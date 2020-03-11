# @summary
#   This class handles installation of Docker and Kubernetes as a single-node cluster.
#
# @note This class assumes installation on a CentOS 7 machine.
#   Docker is installed using systemd as the cgroupdriver.
#
# @param k8s_version
#   The version of Kubernetes to install.
# @param docker_version
#   The version of Docker to install.
#
class slate::kubeadm::packages (
  String $k8s_version = '1.15.5',
  String $docker_version = '19.03.3',
) {
  $kube_packages = ['kubelet', 'kubectl', 'kubeadm']

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
    extra_parameters => ['--exec-opt native.cgroupdriver=systemd'],
  }
  -> package { $kube_packages:
    ensure  => $k8s_version,
    require => Yumrepo['Kubernetes'],
  }
}
