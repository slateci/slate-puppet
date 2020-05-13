# @summary
#   This class creates SLATE administrator accounts and places them in the 'slateadm' group.
#   Which is created if not present.
#
# @see https://forge.puppet.com/puppetlabs/accounts
#
# @param user_accounts
#   An Accounts::User::Hash of users to create.
# @param user_defaults
#   An Accounts::User::Resource containing the default settings
#   to apply to created accounts.
# @param passwordless_sudo
#   If true, users in the 'slateadm' group will have 'NOPASSWD: ALL' sudo privileges.
#   This enables inclusion of /etc/sudoers.d to /etc/sudoers.
#
class slate::accounts (
  Accounts::User::Hash $user_accounts,
  Accounts::User::Resource $user_defaults,
  Boolean $passwordless_sudo,
) {
  group { 'slateadm':
    ensure => present
  }

  $user_accounts.each |Accounts::User::Name $username, Accounts::User::Resource $resource| {
    accounts::user { $username:
      require => Group['slateadm'],
      *       => $user_defaults + $resource,
    }
  }

  if $passwordless_sudo {
    file_line { 'includedir /etc/sudoers.d':
      ensure => present,
      path   => '/etc/sudoers',
      line   => '#includedir /etc/sudoers.d',
    }

    -> file { '/etc/sudoers.d/10_slateadm':
      ensure  => present,
      mode    => '0440',
      content => @(EOT)
        # Allow passwordless sudo for users in 'slateadm'
        # Managed by Puppet
        %slateadm ALL=(ALL) NOPASSWD: ALL
        | EOT
    }
  }
}
