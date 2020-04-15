# @summary
#   This class handles the Kubernetes install for a cluster.
#
class slate::kubernetes (
  # TODO(emersonford): Eliminate initial_controller parameter.
  # Use facts to determine if an initial controller exists or not.
  Boolean $initial_controller,
  Boolean $controller,
  Boolean $worker,
  String $controller_hostname,
  Integer[1, 65565] $controller_port = 6443,
  # This is specific to each controller node.
  Boolean $schedule_on_controller = false,
  # Boolean manage_docker,
  String $docker_version = '19.03.8',
  String $kubernetes_version = '1.18.0',
  # Boolean upgrade_kubernetes,
  Boolean $install_kubectl = true,
  String $cgroup_driver = 'systemd',
  # Ignore the -- in the --flag part and replace - with _.
  Hash[Pattern[/\A[a-z_]+/], Variant[String, Boolean]] $kubeadm_init_flags = {
    'pod_network_cidr' => '192.168.0.0/16',
    'service_cidr' => '10.96.0.0/12',
  },
  Hash[Pattern[/\A[a-z_]+/], Variant[String, Boolean]] $kubeadm_join_flags = {},
  String $cni_network_provider_url = 'https://docs.projectcalico.org/v3.13/getting-started/kubernetes/installation/hosted/kubernetes-datastore/calico-networking/1.7/calico.yaml',
) {
  if $facts['os']['family'] != 'RedHat' or $facts['os']['release']['major'] != '7' {
    fail('This module is only supported on RedHat 7/CentOS 7.')
  }

  # TODO(emersonford): Add checks for existing cluster for init.
  # Change booleans to enums for initial_controller, controller, etc.
  # TODO(emersonford): Add updates for MetalLB and Calico.

  contain slate::kubernetes::packages
  contain slate::kubernetes::pre

  Class['slate::kubernetes::packages']
  -> Class['slate::kubernetes::pre']

  if $worker {
    contain slate::kubernetes::kubeadm_join

    Class['slate::kubernetes::pre']
    -> Class['slate::kubernetes::kubeadm_join']
  }
  elsif $initial_controller {
    contain slate::kubernetes::cluster_init
    contain slate::kubernetes::metallb
    contain slate::kubernetes::roles::controller

    Class['slate::kubernetes::pre']
    -> Class['slate::kubernetes::cluster_init']
    -> Class['slate::kubernetes::metallb']
    -> Class['slate::kubernetes::roles::controller']
  }
  elsif $controller {
    contain slate::kubernetes::kubeadm_join
    contain slate::kubernetes::roles::controller

    Class['slate::kubernetes::pre']
    -> Class['slate::kubernetes::roles::controller']
  }
}
