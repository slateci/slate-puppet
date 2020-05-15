# @summary
#   This class handles setting post global firewall rules as per
#   https://github.com/puppetlabs/puppetlabs-firewall#create-the-my_fwpre-and-my_fwpost-classes
#
# @api private
#
class slate::firewall::post {
  # IPv4 Rules
  firewall { '999 drop all':
    proto  => 'all',
    action => 'reject',
    reject => 'icmp-host-prohibited',
    before => undef,
  }

  firewall { '999 drop all forward':
    chain  => 'FORWARD',
    proto  => 'all',
    action => 'reject',
    reject => 'icmp-host-prohibited',
    before => undef,
  }

  firewallchain { 'INPUT:filter:IPv4':
    ensure => present,
    policy => drop,
    before => undef,
  }

  firewallchain { 'FORWARD:filter:IPv4':
    ensure => present,
    policy => drop,
    before => undef,
  }

  # IPv6 Rules
  firewall { '999 drop all (v6)':
    proto    => 'all',
    action   => 'reject',
    reject   => 'icmp6-adm-prohibited',
    provider => 'ip6tables',
    before   => undef,
  }

  firewall { '999 drop all forward (v6)':
    chain    => 'FORWARD',
    proto    => 'all',
    action   => 'reject',
    reject   => 'icmp6-adm-prohibited',
    provider => 'ip6tables',
    before   => undef,
  }

  firewallchain { 'INPUT:filter:IPv6':
    ensure => present,
    policy => drop,
    before => undef,
  }

  firewallchain { 'FORWARD:filter:IPv6':
    ensure => present,
    policy => drop,
    before => undef,
  }
}
