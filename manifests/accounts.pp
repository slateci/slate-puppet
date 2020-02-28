# @summary
#   This class handles creation of SLATE administrator accounts.
#
# @api private
class slate::accounts (
  Accounts::User::Hash $user_accounts = $slate::user_accounts,
  Accounts::User::Resource $user_defaults = $slate::user_defaults,
  Boolean $passwordless_sudo_on_wheel = $slate::passwordless_sudo_on_wheel,
) {
  include accounts
  $user_accounts.each |Accounts::User::Name $username, Accounts::User::Resource $resource| {
    accounts::user { $username:
      * => $user_defaults + $resource,
    }
  }

  if $passwordless_sudo_on_wheel {
    include 'sudo'
    sudo::conf { 'wheel':
      priority => 10,
      content  => '%wheel ALL=(ALL) NOPASSWD: ALL',
    }
  }
}
