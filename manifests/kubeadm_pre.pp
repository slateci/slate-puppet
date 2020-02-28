# @summary
#   This class handles k8s installation.
#
# @api private
class slate::kubeadm_pre () {
  class { 'selinux':
    mode => 'permissive',
  }

  exec { 'disable swap':
    path    => ['/usr/sbin', '/usr/bin', '/bin', '/sbin'],
    command => 'swapoff -a',
    unless  => "awk '{ if (NR > 1) exit 1}' /proc/swaps",
  }

  # Tuning of sysctl
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

  sysctl { 'net.core.rmem_max':
    ensure => present,
    value  => '67108864',
  }

  sysctl { 'net.core.wmem_max':
    ensure => present,
    value  => '67108864',
  }

  sysctl { 'net.ipv4.tcp_rmem':
    ensure => present,
    value  => '4096 87380 33554432',
  }

  sysctl { 'net.ipv4.tcp_wmem':
    ensure => present,
    value  => '4096 65536 33554432',
  }

  sysctl { 'net.ipv4.tcp_congestion_control':
    ensure => present,
    value  => 'htcp',
  }

  sysctl { 'net.ipv4.tcp_mtu_probing':
    ensure => present,
    value  => '1',
  }

  sysctl { 'net.core.default_qdisc':
    ensure => present,
    value  => 'fq',
  }


  # TODO(emersonf): Change this to a specific port list.
  class { 'firewalld':
    service_enable => false,
    service_ensure => stopped,
  }

  if $slate::disable_root_ssh {
    file_line { 'PermitRootLogin no':
      line => 'PermitRootLogin no',
      path => '/etc/ssh/sshd_config',
    }
    file_line { 'PermitRootLogin yes':
      ensure => absent,
      line   => 'PermitRootLogin yes',
      path   => '/etc/ssh/sshd_config',
    }
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
