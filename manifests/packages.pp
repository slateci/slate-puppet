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

  exec { 'install EPEL':
    command => 'yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm -y',
    unless  => 'yum repolist -q | awk "{print $1}" | grep epel',
    path    => ['/usr/sbin', '/usr/bin', '/bin', '/sbin', '/usr/local/bin'],
  }

  ensure_packages($package_list, {
    ensure => latest,
    require => Exec['install EPEL']
  })

  if $install_dell_tools and $facts['manufacturer'] == 'Dell Inc.' {
    contain slate::dell::racadm
    contain slate::dell::dsu
  }
}
