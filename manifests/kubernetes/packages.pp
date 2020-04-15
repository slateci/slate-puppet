# @summary
#   This class handles installation of Docker and Kubernetes packages.
#
# @api private
#
# @param install_kubectl
#   If true installs kubectl.
# @param kubernetes_version
#   The version of the Kubernetes packages to install.
# @param docker_version
#   The version of Docker to install.
# @param docker_cgroup_driver
#   The cgroup driver to use for Docker.
#
class slate::kubernetes::packages (
  Boolean $install_kubectl = $slate::kubernetes::install_kubectl,
  String $kubernetes_version = $slate::kubernetes::kubernetes_version,
  String $docker_version = $slate::kubernetes::docker_version,
  String $docker_cgroup_driver = $slate::kubernetes::cgroup_driver,
) {
  if $install_kubectl {
    $kube_packages = ['kubelet', 'kubectl', 'kubeadm']
  }
  else {
    $kube_packages = ['kubelet', 'kubeadm']
  }

  yumrepo { 'Kubernetes':
    ensure        => 'present',
    name          => 'kubernetes',
    baseurl       => 'https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64',
    enabled       => '1',
    gpgcheck      => '1',
    repo_gpgcheck => '1',
    gpgkey        => 'https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg',
  }

  class { 'docker':
    version          => $docker_version,
    extra_parameters => ["--exec-opt native.cgroupdriver=${docker_cgroup_driver}"],
  }
  -> package { $kube_packages:
    ensure  => $kubernetes_version,
    require => Yumrepo['Kubernetes'],
  }
}
