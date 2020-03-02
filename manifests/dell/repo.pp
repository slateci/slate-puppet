# @summary
#   This class handles installation of Dell's DSU repository.
#
# @api private
class slate::dell::repo {
  require slate::dell::keys
  $key_names = $slate::dell::keys::key_names

  yumrepo { 'dell-system-update_independent':
    name     => 'dell-system-update_independent',
    baseurl  => 'https://linux.dell.com/repo/hardware/dsu/os_independent/',
    gpgkey   => join(($key_names.map |String $key_name| {"https://linux.dell.com/repo/pgp_pubkeys/${key_name}.asc"}), "\n\t"),
    gpgcheck => '1',
    enabled  => '1',
    exclude  => 'dell-system-update*.i386'
  }

  yumrepo { 'dell-system-update_dependent':
    name       => 'dell-system-update_dependent',
    mirrorlist => "https://linux.dell.com/repo/hardware/dsu/mirrors.cgi?osname=el${facts['os']['release']['major']}&basearch=x86_64&native=1",
    gpgkey     => join(($key_names.map |String $key_name| {"https://linux.dell.com/repo/pgp_pubkeys/${key_name}.asc"}), "\n\t"),
    gpgcheck   => '1',
    enabled    => '1',
  }
}
