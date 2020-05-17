# @summary
#   This class handles the configuration of kubelet on nodes.
#
# @param cgroup_driver
#   See slate::kubernetes::cgroup_driver.
#
class slate::kubernetes::kubelet (
  String $cgroup_driver = $slate::kubernetes::cgroup_driver,
) {
  file { '/etc/systemd/system/kubelet.service.d':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }
  # RedHat needs to have CPU and Memory accounting enabled to avoid systemd proc errors
  # https://github.com/kubernetes/kubernetes/issues/85883
  # https://github.com/kubernetes/kubernetes/issues/56850
  -> file { '/etc/systemd/system/kubelet.service.d/11-cgroups.conf':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => "[Service]\nCPUAccounting=true\nMemoryAccounting=true\n",
    notify  => Exec['kubernetes-systemd-reload'],
  }
  # Sometimes kubelet can start before Docker, causing kubelet to die. This fixes that race condition.
  -> file { '/etc/systemd/system/kubelet.service.d/12-after-docker.conf':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => "[Unit]\nAfter=docker.service",
    notify  => Exec['kubernetes-systemd-reload'],
  }

  # Update the kubelet config only if this node has been joined to a cluster.
  # Else kubelet will autodiscover our cgroupDriver in the kubeadm process.
  if fact('slate.kubernetes.kubelet_cluster_host') {
    file_line { 'kubelet-cgroup-config':
      ensure => present,
      path   => '/var/lib/kubelet/config.yaml',
      line   => "cgroupDriver: ${cgroup_driver}",
      match  => '^cgroupDriver:[\w ]*$',
      notify => Exec['kubernetes-systemd-reload'],
    }
  }

  exec { 'kubernetes-systemd-reload':
    path        => '/bin',
    command     => 'systemctl daemon-reload',
    refreshonly => true,
  }
  ~> service { 'kubelet':
    ensure  => running,
    enable  => true,
    require => Service['docker'],
  }
}
