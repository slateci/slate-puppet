# @summary
#   This class handles setting pre global firewall rules as per
#   https://github.com/puppetlabs/puppetlabs-firewall#create-the-my_fwpre-and-my_fwpost-classes
#
# @api private
#
class slate::firewall::pre {
  Firewall {
    require => undef,
  }

  # IPv4 Rules
  firewall { '000 accept all icmp':
    proto  => 'icmp',
    action => 'accept',
  }
  -> firewall { '001 accept all to lo interface':
    proto   => 'all',
    iniface => 'lo',
    action  => 'accept',
  }
  -> firewall { '002 reject local traffic not on loopback interface':
    iniface     => '! lo',
    proto       => 'all',
    destination => '127.0.0.1/8',
    action      => 'reject',
  }
  -> firewall { '003 accept related established rules':
    proto  => 'all',
    state  => ['RELATED', 'ESTABLISHED'],
    action => 'accept',
  }
  -> firewall { '004 rate-limit SSH to 4 connections/5 minutes':
    dport     => 22,
    proto     => 'tcp',
    state     => ['NEW'],
    recent    => 'update',
    rseconds  => 300,
    rhitcount => 4,
    rname     => 'SSHRATELIM',
    rsource   => true,
    action    => 'reject',
    reject    => 'icmp-host-prohibited',
  }
  -> firewall { '005 set SSH rate-limit':
    dport   => 22,
    proto   => 'tcp',
    state   => ['NEW'],
    recent  => 'set',
    rname   => 'SSHRATELIM',
    rsource => true,
  }
  -> firewall { '006 allow inbound SSH':
    dport  => 22,
    proto  => 'tcp',
    action => 'accept',
  }

  # IPv6 Rules
  firewall { '000 accept all icmp (v6)':
    proto    => 'ipv6-icmp',
    action   => 'accept',
    provider => 'ip6tables',
  }
  -> firewall { '001 accept all to lo interface (v6)':
    proto    => 'all',
    iniface  => 'lo',
    action   => 'accept',
    provider => 'ip6tables',
  }
  -> firewall { '002 reject local traffic not on loopback interface (v6)':
    iniface     => '! lo',
    proto       => 'all',
    destination => '::1/128',
    action      => 'reject',
    provider    => 'ip6tables',
  }
  -> firewall { '003 accept related established rules (v6)':
    proto    => 'all',
    state    => ['RELATED', 'ESTABLISHED'],
    action   => 'accept',
    provider => 'ip6tables',
  }
  -> firewall { '004 rate-limit SSH to 4 connections/5 minutes (v6)':
    dport     => 22,
    proto     => 'tcp',
    state     => ['NEW'],
    action    => 'reject',
    reject    => 'icmp6-adm-prohibited',
    recent    => 'update',
    rseconds  => 300,
    rhitcount => 4,
    rname     => 'SSHRATELIM',
    rsource   => true,
    provider  => 'ip6tables',
  }
  -> firewall { '005 set SSH rate-limit (v6)':
    dport    => 22,
    proto    => 'tcp',
    state    => ['NEW'],
    recent   => 'set',
    rname    => 'SSHRATELIM',
    rsource  => true,
    provider => 'ip6tables',
  }
  -> firewall { '006 allow inbound SSH (v6)':
    dport    => 22,
    proto    => 'tcp',
    action   => 'accept',
    provider => 'ip6tables',
  }
  -> firewall { '007 allow dhcpv6-client (v6)':
    dport       => 546,
    proto       => 'udp',
    state       => ['NEW'],
    action      => 'accept',
    destination => 'fe80::/64',
    provider    => 'ip6tables',
  }
}
