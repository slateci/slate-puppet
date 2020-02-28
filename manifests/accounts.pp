# @summary
#   This class handles creation of SLATE administrator accounts.
#
# @api private
class slate::accounts (
  $user_accounts = $slate::user_accounts,
  $user_defaults = $slate::user_defaults,
  $passwordless_sudo_on_wheel = $slate::passwordless_sudo_on_wheel,
) {
  class { 'accounts':
    user_list     => $slate::user_accounts,
    user_defaults => $slate::user_defaults,
  }

  if $passwordless_sudo_on_wheel {
    include 'sudo'
    sudo::conf { 'wheel':
      priority => 10,
      content  => '%wheel ALL=(ALL) NOPASSWD: ALL',
    }
  }
}
