# @summary
#   This class creates SLATE administrator accounts.
#
# @see https://forge.puppet.com/puppetlabs/accounts
#
# @note If the username is already managed by some other Puppet module,
#   this module will not manage the user.
#
# @param user_accounts
#   An Accounts::User::Hash of users to create.
# @param user_defaults
#   An Accounts::User::Resource containing the default settings
#   to apply to created accounts.
# @param passwordless_sudo
#   If true, users in the 'wheel' group will have 'NOPASSWD: ALL' sudo privileges.
#
class slate::accounts (
  Accounts::User::Hash $user_accounts,
  Accounts::User::Resource $user_defaults,
  Boolean $passwordless_sudo,
) {
  include accounts
  $user_accounts.each |Accounts::User::Name $username, Accounts::User::Resource $resource| {
    ensure_resource('accounts::user', $username, $user_defaults + $resource)
  }

  if $passwordless_sudo {
    file_line { 'includedir /etc/sudoers.d':
      ensure => present,
      path   => '/etc/sudoers',
      line   => '#includedir /etc/sudoers.d',
    }

    -> file { '/etc/sudoers.d/10_wheel':
      ensure  => present,
      mode    => '0440',
      content => @(EOT)
        # Allow passwordless sudo for users in 'wheel'
        # Managed by Puppet
        %wheel ALL=(ALL) NOPASSWD: ALL
        | EOT
    }
  }
}
