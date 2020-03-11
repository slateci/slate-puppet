# @summary
#   This class handles installation of SLATE required packages.
#
# @param install_dell_tools
#   Installs RACADM and dsu if the manufacturer is 'Dell Inc.'
# @param package_list
#   The list of package names to install.
# @param slate_tmp_dir
#   The directory to unpack the SLATE CLI into.
#
class slate::packages (
  Boolean $install_dell_tools = true,
  Array $package_list = ['htop', 'strace', 'tmux', 'iftop', 'screen', 'sysstat', 'jq', 'curl'],
  String $slate_tmp_dir = $slate::slate_tmp_dir,
) {
  $slate_cli_pkg = "${slate_tmp_dir}/slate-linux.tar.gz"

  package { $package_list:
    ensure => latest,
  }

  file { $slate_tmp_dir:
    ensure => directory,
  }
  -> exec { 'download SLATE CLI':
    path        => ['/usr/sbin', '/usr/bin', '/bin', '/sbin', '/usr/local/bin'],
    command     => "curl -L https://jenkins.slateci.io/artifacts/client/slate-linux.tar.gz -o ${slate_cli_pkg}",
    # Do not run if the SLATE binary is present and it's version is equal to the server's reported version.
    unless      => 'test -f /usr/local/bin/slate && \
    test $(slate version | grep -Pzo "Client Version.*\\n\\K(\\d+)(?=.*)") = \
    $(curl -L https://jenkins.slateci.io/artifacts/client/latest.json | \
    jq -r ".[0].version")',
    environment => ['HOME=/root'],
  }
  ~> exec { 'untar SLATE CLI':
    path        => ['/usr/sbin', '/usr/bin', '/bin', '/sbin'],
    command     => "tar -xf ${slate_cli_pkg} -C /usr/local/bin",
    refreshonly => true,
  }

  if $install_dell_tools and $facts['manufacturer'] == 'Dell Inc.' {
    contain slate::dell::racadm
    contain slate::dell::dsu
  }
}
