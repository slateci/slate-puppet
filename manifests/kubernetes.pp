# @summary
#   This class handles the Kubernetes instantiation for specific nodes, then either instantiates a cluster or joins them to a cluster
#   depending on what the node role is set to. The cluster will be spun up with Calico as the CNI and MetalLB as the load balancer.
#   The cluster will also be instantiated as a high-availability cluster. Docker is used as the CRI. The installation process and joining
#   process are handled by `kubeadm`. Joining new nodes is quite painless as the join tokens are, by default, distributed using PuppetDB,
#   thus manual distribution of those secrets is not necessary.
#
# @note This module can manage existing Kubernetes cluster non-destructively, i.e. you can use this module to join new nodes to an
#   existing cluster that was not instantiated with this module. However, if the cluster was originally setup as a single-availability
#   cluster, you cannot add additional controller nodes to the cluster but can add additional worker nodes.
#
# @note This module can theoretically handle updating both MetalLB and Calico on a cluster, but this is not well tested nor well
#   supported. If changing either's version numbers, proceed with caution.
#
# @note This module does not support upgrading clusters. However, you can use this module as a step in the upgrade process by changing
#   the `kubernetes_version` to the desired version to upgrade the `kubectl`, `kubeadm`, and `kubelet` packages which is required by
#   https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/
#
# @note This module does not support management of any other configuration states of the cluster.
#
# @note Kubernetes cluster instantiation and joining is a heavily imperative process, which does not conform well to Puppet's declarative
#   paradigm. When changing any parameter after instantiation, please proceed with caution as there may be unexpected results.
#
#
# @param role
#   If set to initial_controller and the node is not currently joined in a cluster, instantiate a new cluster.
#   If set to controller, join this node to the specified cluster as a controller node.
#   If set to worker, join this node to the specified cluster as a worker node.
# @param docker_version
#   The version of Docker to use.
# @param kubernetes_version
#   The version of `kubectl`, `kubeadm`, and `kubelet` to install.
#   Note, changing this after cluster instantiation/joining without following the "kubeadm-upgrade" instructions will result in undefined
#   behavior. This value should _be the same for all nodes in a given cluster_, unless you are in the middle of upgrading a cluster.
# @param controller_hostname
#   The hostname the cluster should listen on.
#   For clusters intended to be high-availability, this should be the hostname of a load balancer, NOT a controller node. See
#   https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/high-availability/#create-load-balancer-for-kube-apiserver.
#   For clusters intended to be single-availability, you can set this to the hostname of the single controller node.
# @param controller_port
#   The port the cluster should listen on.
#   Similarly to `controller_hostname`, this should be the port of the load balancer if the cluster is intended to be a high-availability
#   cluster. If it is intended to be a single-availability cluster, you can set this to the port of the single controller node.
# @param schedule_on_controller
#   If true and role is set to 'initial_controller' or 'controller', this node will be untainted to allow for Pods to be scheduled on
#   this node.
#   If false and role is set to 'initial_controller' or 'controller', this node will be tainted to prevent Pods from being scheduled on it.
#   Note, this is specific to individual controller nodes.
#   Note, this is required to be set to true for single node clusters.
# @param cgroup_driver
#   The cgroup_driver to use with Docker. The kubelet config is changed to reflect this cgroup_driver.
#
class slate::kubernetes (
  Enum[
    'initial_controller',
    'controller',
    'worker'
  ] $role,
  String $docker_version,
  String $kubernetes_version,
  String $controller_hostname,
  Integer[1, 65565] $controller_port,
  Boolean $schedule_on_controller,
  String $cgroup_driver,
) {
  if fact('slate.kubernetes.kubelet_cluster_host') != undef and
    (fact('slate.kubernetes.kubelet_cluster_host') != $controller_hostname or
    fact('slate.kubernetes.kubelet_cluster_port') != String($controller_port)) {
      fail(
        @("EOF"/L)
        This node is already registered with \
        ${fact('slate.kubernetes.kubelet_cluster_host')}:${fact('slate.kubernetes.kubelet_cluster_port')}, \
        cannot register with ${controller_hostname}:${controller_port}!
        | EOF
      )
  }

  contain slate::kubernetes::packages
  contain slate::kubernetes::pre
  contain slate::kubernetes::security
  contain slate::kubernetes::kubelet

  Class['slate::kubernetes::packages']
  -> Class['slate::kubernetes::pre']
  -> Class['slate::kubernetes::security']
  -> Class['slate::kubernetes::kubelet']

  case $role {
    'worker': {
      contain slate::kubernetes::worker

      Class['slate::kubernetes::kubelet']
      -> Class['slate::kubernetes::worker']
    }
    /controller/: {
      contain slate::kubernetes::controller

      Class['slate::kubernetes::kubelet']
      -> Class['slate::kubernetes::controller']
    }
    default: {
      fail("Unsupported role: ${role}")
    }
  }
}
