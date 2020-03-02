# @summary
#   This class handles installation of the DSU utility to update firmware.
#
# @api private
class slate::dell::dsu {
  require slate::dell::repo

  package {'dell-system-update':
    ensure  => latest,
  }
}
