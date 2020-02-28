# @summary
#   This class handles installation of the DSU utility to update firmware.
#
# @api private
class slate::dsu::dsu {
  require slate::dsu::repo

  package {'dell-system-update':
    ensure  => latest,
  }
}
