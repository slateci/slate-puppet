# @summary
#   This class handles installation of Docker and Kubernetes packages.
#
# @param install_kubectl
#   If true installs kubectl. By default, this is only true on controller nodes.
# @param kubernetes_version
#   See slate::kubernetes::kubernetes_version.
# @param docker_version
#   See slate::kubernetes::docker_version.
# @param docker_cgroup_driver
#   See slate::kubernetes::cgroup_driver.
#
class slate::kubernetes::packages (
  Boolean $install_kubectl = $slate::kubernetes::role =~ /controller/,
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

  if 'kubectl' in $kube_packages {
    exec { 'setup kubectl completions':
      path        => ['/usr/sbin', '/usr/bin', '/bin', '/sbin', '/usr/local/bin'],
      command     => 'kubectl completion bash > /etc/bash_completion.d/kubectl',
      refreshonly => true,
      environment => ['HOME=/root'],
      subscribe   => Package['kubectl'],
    }
  }

  if 'kubeadm' in $kube_packages {
    exec { 'setup kubeadm completions':
      path        => ['/usr/sbin', '/usr/bin', '/bin', '/sbin', '/usr/local/bin'],
      command     => 'kubeadm completion bash > /etc/bash_completion.d/kubeadm',
      refreshonly => true,
      environment => ['HOME=/root'],
      subscribe   => Package['kubeadm'],
    }
  }
}
