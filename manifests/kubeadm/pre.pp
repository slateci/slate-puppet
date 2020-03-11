# @summary
#   This class handles pre-Kubernetes installation steps such as disabling swap,
#   setting up kernel modules, etc.
#
# @api private
#
class slate::kubeadm::pre {
  exec { 'disable swap':
    path    => ['/usr/sbin', '/usr/bin', '/bin', '/sbin'],
    command => 'swapoff -a',
    unless  => "awk '{ if (NR > 1) exit 1}' /proc/swaps",
  }

  file_line { 'disable swap in /etc/fstab':
    ensure            => absent,
    path              => '/etc/fstab',
    match             => '.+\sswap\s.+',
    match_for_absence => true,
    multiple          => true,
  }

  # Set up the required sysctl configs and kernel modules.
  kmod::load { 'br_netfilter':
    before => Sysctl['net.bridge.bridge-nf-call-iptables'],
  }

  sysctl { 'net.bridge.bridge-nf-call-iptables':
    ensure => present,
    value  => '1',
    before => Sysctl['net.ipv4.ip_forward'],
  }

  sysctl { 'net.bridge.bridge-nf-call-ip6tables':
    ensure => present,
    value  => '1',
    before => Sysctl['net.ipv6.conf.all.forwarding'],
  }

  sysctl { 'net.ipv4.ip_forward':
    ensure => present,
    value  => '1',
  }

  sysctl { 'net.ipv6.conf.all.forwarding':
    ensure => present,
    value  => '1',
  }

  file { '/etc/systemd/system/kubelet.service.d':
    ensure => directory,
  }

  file { '/etc/sysconfig/kubelet':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }
  -> file_line { 'read-only-port':
    line   => 'KUBELET_EXTRA_ARGS="--read-only-port=10255"',
    path   => '/etc/sysconfig/kubelet',
    notify => Service['kubelet'],
  }

  exec { 'kubernetes-systemd-reload':
    path        => '/bin',
    command     => 'systemctl daemon-reload',
    refreshonly => true,
  }

  # RedHat needs to have CPU and Memory accounting enabled to avoid systemd proc errors
  if $facts['os']['family'] == 'RedHat' {
    file { '/etc/systemd/system/kubelet.service.d/11-cgroups.conf':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => "[Service]\nCPUAccounting=true\nMemoryAccounting=true\n",
      require => File['/etc/systemd/system/kubelet.service.d'],
      notify  => Exec['kubernetes-systemd-reload'],
    }
  }
}
