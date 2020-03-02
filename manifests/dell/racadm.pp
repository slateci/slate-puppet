# @summary
#   This class handles installation of RACADM.
#
# @api private
class slate::dell::racadm {
  require slate::dell::repo

  package {'srvadmin-idracadm7':
    ensure  => latest,
  }
}
