# @summary
#   This class handles setting specific security settings required per node for SLATE.
#   As we solidify our per-node security policy, we should add to this.
#
# @param disable_root_ssh
#   If true, ensures 'PermitRootLogin no' is set in `/etc/ssh/sshd_config`.
#   If false, ensures 'PermitRootLogin yes' is set in `/etc/ssh/sshd_config`.
#
class slate::security (
  Boolean $disable_root_ssh = true,
) {
  # Allows us to restart sshd on config change without managing the SSSD service via Puppet.
  exec { 'sshd-system-reload':
    path        => '/bin',
    command     => 'systemctl is-active --quiet sshd || exit 0; systemctl reload sshd',
    refreshonly => true,
  }

  if $disable_root_ssh {
    file_line { 'PermitRootLogin no':
      line   => 'PermitRootLogin no',
      path   => '/etc/ssh/sshd_config',
      notify => Exec['sshd-system-reload'],
    }

    file_line { 'PermitRootLogin yes':
      ensure => absent,
      line   => 'PermitRootLogin yes',
      path   => '/etc/ssh/sshd_config',
      notify => Exec['sshd-system-reload'],
    }
  }
  else {
    file_line { 'PermitRootLogin yes':
      line   => 'PermitRootLogin yes',
      path   => '/etc/ssh/sshd_config',
      notify => Exec['sshd-system-reload'],
    }

    file_line { 'PermitRootLogin no':
      ensure => absent,
      line   => 'PermitRootLogin no',
      path   => '/etc/ssh/sshd_config',
      notify => Exec['sshd-system-reload'],
    }
  }
}
