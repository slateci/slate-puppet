# @summary
#   This class handles pre-Kubernetes installation steps such as disabling swap,
#   setting up kernel modules, etc.
#
# @api private
#
# @param kubelet_cgroup_driver
#   The cgroup driver Kubelet should use.
#
class slate::kubernetes::pre (
  String $kubelet_cgroup_driver = $slate::kubernetes::cgroup_driver,
) {
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
    # before    => [
    #   Sysctl['net.bridge.bridge-nf-call-iptables'],
    #   Sysctl['net.bridge.bridge-nf-call-ip6tables'],
    # ],
  }

  # Use this when https://github.com/hercules-team/augeasproviders_sysctl/issues/41 is fixed.
  # sysctl { 'net.bridge.bridge-nf-call-iptables':
  #   ensure => present,
  #   value  => '1',
  #   apply  => true,
  # }

  # -> sysctl { 'net.ipv4.ip_forward':
  #   ensure => present,
  #   value  => '1',
  # }

  # sysctl { 'net.bridge.bridge-nf-call-ip6tables':
  #   ensure => present,
  #   value  => '1',
  #   apply  => true,
  # }

  # -> sysctl { 'net.ipv6.conf.all.forwarding':
  #   ensure => present,
  #   value  => '1',
  # }

  -> file { '/etc/sysctl.d/k8s.conf':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => @(EOF/L)
    net.bridge.bridge-nf-call-ip6tables = 1
    net.bridge.bridge-nf-call-iptables = 1
    net.ipv4.ip_forward = 1
    net.ipv6.conf.all.forwarding = 1
    | - EOF
  }

  ~> exec { 'refresh sysctl':
    command     => 'sysctl --system',
    path        => ['/usr/bin', '/bin', '/sbin', '/usr/local/bin'],
    refreshonly => true,
  }


  file { '/etc/sysconfig/kubelet':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }
  -> file_line { 'read-only-port':
    ensure => present,
    line   => "KUBELET_EXTRA_ARGS=\"--read-only-port=10255 --cgroup-driver=${kubelet_cgroup_driver}\"",
    path   => '/etc/sysconfig/kubelet',
  }
  ~> exec { 'kubernetes-systemd-reload':
    path        => '/bin',
    command     => 'systemctl daemon-reload',
    refreshonly => true,
  }
  ~> service { 'kubelet':
    ensure  => running,
    enable  => true,
    require => Service['docker'],
  }

  # RedHat needs to have CPU and Memory accounting enabled to avoid systemd proc errors
  if $facts['os']['family'] == 'RedHat' {
    file { '/etc/systemd/system/kubelet.service.d':
      ensure => directory,
    }
    -> file { '/etc/systemd/system/kubelet.service.d/11-cgroups.conf':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => "[Service]\nCPUAccounting=true\nMemoryAccounting=true\n",
      notify  => Exec['kubernetes-systemd-reload'],
    }
  }
}
