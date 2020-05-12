# @summary
#   This class handles installation of SLATE required packages.
#
# @param install_dell_tools
#   Installs RACADM and dsu if the manufacturer is 'Dell Inc.'
# @param package_list
#   The list of package names to install.
#
class slate::packages (
  Boolean $install_dell_tools = true,
  Array $package_list = ['htop', 'strace', 'tmux', 'iftop', 'screen', 'sysstat', 'jq', 'curl'],
) {
  package { $package_list:
    ensure => latest,
  }

  if $install_dell_tools and $facts['manufacturer'] == 'Dell Inc.' {
    contain slate::dell::racadm
    contain slate::dell::dsu
  }
}
