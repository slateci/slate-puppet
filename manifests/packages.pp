# @summary
#   This class handles installation of SLATE necessary packages.
#
# @api private
class slate::packages {
  $slate_cli_pkg = "${slate::slate_tmp_dir}/slate-linux.tar.gz"
  $kube_packages = ['kubelet', 'kubectl', 'kubeadm']

  package { $slate::package_list:
    ensure => latest,
  }

  yumrepo { 'Kubernetes':
    ensure        => 'present',
    baseurl       => 'https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64',
    enabled       => '1',
    gpgcheck      => '1',
    repo_gpgcheck => '1',
    gpgkey        => 'https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg',
  }

  class { 'docker':
    version          => $slate::docker_version,
    extra_parameters => ['--exec-opt native.cgroupdriver=systemd'],
  }
  -> package { $kube_packages:
    ensure  => $slate::k8s_version,
    require => Yumrepo['Kubernetes'],
  }

  file { $slate::slate_tmp_dir:
    ensure => directory,
  }
  -> exec { 'download SLATE CLI':
    path    => ['/usr/sbin', '/usr/bin', '/bin', '/sbin'],
    command => "curl -L https://jenkins.slateci.io/artifacts/client/slate-linux.tar.gz -o ${slate_cli_pkg}",
    # Do not run if the SLATE binary is present and it's version is equal to the server's reported version.
    unless  => "test -f /usr/local/bin/slate
    && [ `slate version 2>/dev/null | egrep '[0-9]+'` -eq `curl -L https://jenkins.slateci.io/artifacts/client/latest.json 2> /dev/null | jq -r '.[0].version'` ]",
  }
  ~> exec { 'untar SLATE CLI':
    path        => ['/usr/sbin', '/usr/bin', '/bin', '/sbin'],
    command     => "tar -xf ${slate_cli_pkg} -C /usr/local/bin",
    refreshonly => true,
  }
}
