# @summary
#   This class handles installation of SLATE necessary packages.
#
# @api private
class slate::packages {
  $slate_cli_pkg = "${slate::slate_tmp_dir}/slate-linux.tar.gz"

  package { $slate::package_list:
    ensure => latest,
  }

  class { 'docker':
    version => $slate::docker_version,
  }

  file { $slate::slate_tmp_dir:
    ensure => directory,
  }
  -> exec { 'download SLATE CLI':
    path    => ['/usr/sbin/', '/usr/bin', '/bin', '/sbin'],
    command => "curl -L https://jenkins.slateci.io/artifacts/client/slate-linux.tar.gz -o ${slate_cli_pkg}",
    # If the SLATE CLI package is more than 5 days old, pull and update.
    unless  => "stat ${slate_cli_pkg} --format='%Y' 1> /dev/null 2> /dev/null && \
    [ $((`date +%s` - `stat ${slate_cli_pkg} --format='%Y'`)) -lt 432000 ]",
  }
  ~> exec { 'untar SLATE CLI':
    path        => ['/usr/sbin/', '/usr/bin', '/bin', '/sbin'],
    command     => "tar -xf ${slate_cli_pkg} -C /usr/local/bin",
    refreshonly => true,
  }
}
