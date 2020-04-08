# @summary
#   This class handles tuning of sysctl parameters for SLATE.
#
class slate::tuning {
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
}
