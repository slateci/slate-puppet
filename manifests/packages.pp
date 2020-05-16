# @summary
#   This class handles installation of SLATE required packages and the SLATE CLI.
#
# @param package_list
#   The list of package names to install.
# @param install_dell_tools
#   Installs RACADM and dsu if the manufacturer is 'Dell Inc.'
#
class slate::packages (
  Array $package_list,
  Boolean $install_dell_tools = true,
) {
  contain slate::cli

  package { $package_list:
    ensure => latest,
  }

  if $install_dell_tools and $facts['manufacturer'] == 'Dell Inc.' {
    contain slate::dell::racadm
    contain slate::dell::dsu
  }
}
