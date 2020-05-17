# @summary
#   This class handles setting specific security settings required per node for SLATE.
#   This module will manage some firewall rules through iptables (ergo disabling firewalld).
#   This module will also disable root login through SSH.
#
# @note The firewall module will order rules starting with '000' to '899' before unmanaged rules.
#   Rules starting with '900' to '999' will be placed after unmanaged rules.
#
# @see https://github.com/puppetlabs/puppetlabs-firewall
#
# @param slate_ports
#   List of TCP ports to open for a SLATE-specific needs.
#
class slate::security (
  Array[String] $slate_ports = [],
) {
  include 'slate::firewall::pre'
  include 'slate::firewall::post'

  # We will manage the default rules in Puppet, so disable their creation.
  # These files will have to be updated for CentOS 8.
  exec { 'disable default iptables rule':
    path    => ['/usr/bin', '/bin'],
    command => 'touch /etc/sysconfig/iptables',
    unless  => 'test -f /etc/sysconfig/iptables',
  }

  exec { 'disable default ip6tables rule':
    path    => ['/usr/bin', '/bin'],
    command => 'touch /etc/sysconfig/ip6tables',
    unless  => 'test -f /etc/sysconfig/ip6tables',
  }

  # Disables firewalld in favor of iptables.
  class { 'firewall':
    ensure     => running,
    ensure_v6  => running,
    pkg_ensure => latest,
    require    => [
      Exec['disable default iptables rule'],
      Exec['disable default ip6tables rule'],
    ]
  }

  # Per instructions in https://github.com/puppetlabs/puppetlabs-firewall
  Firewall {
    before  => Class['slate::firewall::post'],
    require => Class['slate::firewall::pre'],
  }
  -> firewallchain { 'SLATE-GENERAL:filter:IPv4':
    ensure => present,
  }

  firewall { '200 check general SLATE ports':
    proto => 'tcp',
    jump  => 'SLATE-GENERAL',
    chain => 'INPUT',
  }

  if length($slate_ports) > 0 {
    firewall { '100 accept general SLATE ports':
      proto  => 'tcp',
      dport  => $slate_ports,
      action => 'accept',
      state  => 'NEW',
      chain  => 'SLATE-GENERAL',
    }
  }

  file_line { 'PermitRootLogin no':
    line  => 'PermitRootLogin no',
    path  => '/etc/ssh/sshd_config',
    match => '^PermitRootLogin[\w ]*$',
  }
  # Allows us to restart sshd on config change without managing the SSHD service via Puppet.
  ~> exec { 'sshd-system-reload':
    path        => '/bin',
    command     => 'systemctl is-active --quiet sshd || exit 0; systemctl reload sshd',
    refreshonly => true,
  }
}
