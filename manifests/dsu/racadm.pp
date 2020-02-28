# @summary
#   This class handles installation of RACADM.
#
# @api private
class slate::dsu::racadm {
  require slate::dsu::repo

  package {'srvadmin-idracadm7':
    ensure  => latest,
  }
}
