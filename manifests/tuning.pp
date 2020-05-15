# @summary
#   This class handles tuning of sysctl parameters for SLATE.
#
# @param tuning_sysctl_path
#   Path to store tuning sysctl parameters.
#
class slate::tuning (
  String $tuning_sysctl_path = '/etc/sysctl.d/fasterdata.conf',
) {
  # TODO(emersonford): Investigate using
  # https://puppet.com/docs/puppet/5.5/resources_augeas.html#etcsysctlconf

  file { $tuning_sysctl_path:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => @(EOF/L)
    # allow testing with buffers up to 64MB
    net.core.rmem_max = 67108864
    net.core.wmem_max = 67108864
    net.ipv4.tcp_rmem = 4096 87380 33554432
    net.ipv4.tcp_wmem = 4096 65536 33554432
    net.ipv4.tcp_congestion_control=htcp
    net.ipv4.tcp_mtu_probing=1
    net.core.default_qdisc = fq
    | - EOF
  }

  ~> exec { "refresh sysctl ${tuning_sysctl_path}":
    command     => "sysctl -p ${tuning_sysctl_path}",
    path        => ['/usr/bin', '/bin', '/sbin', '/usr/local/bin'],
    refreshonly => true,
  }
}
