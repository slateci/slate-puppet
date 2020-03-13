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
# @param passwordless_sudo_on_wheel
#   If true, users in group 'wheel' will have NOPASSWD sudo access.
#
class slate::accounts (
  Accounts::User::Hash $user_accounts,
  Accounts::User::Resource $user_defaults,
  Boolean $passwordless_sudo_on_wheel,
) {
  include accounts
  $user_accounts.each |Accounts::User::Name $username, Accounts::User::Resource $resource| {
    ensure_resource('accounts::user', $username, $user_defaults + $resource)
  }

  if $passwordless_sudo_on_wheel {
    include 'sudo'
    sudo::conf { 'wheel':
      priority => 10,
      content  => '%wheel ALL=(ALL) NOPASSWD: ALL',
    }
  }
}
