# @summary
#   This class handles creation of SLATE administrator accounts.
#
# @api private
class slate::accounts () {
  if $slate::user_accounts != undef and $slate::user_defaults != undef {
    class { 'accounts':
      user_list     => $slate::user_accounts,
      user_defaults => $slate::user_defaults,
    }
  }
  elsif $slate::user_accounts != undef {
    class { 'accounts':
      user_list     => $slate::user_accounts,
    }
  }

  include 'sudo'
  sudo::conf { 'wheel':
    priority => 10,
    content  => '%wheel ALL=(ALL) NOPASSWD: ALL',
  }
}
