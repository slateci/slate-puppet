# @summary
#   This class handles installation of Dell's public keys.
#
# @api private
class slate::dell::keys (
  $key_names = ['0x756ba70b1019ced6', '0x1285491434D8786F', '0xca77951d23b66a9d']
) {
  file { '/usr/libexec/dell_dup':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  $key_names.each |String $key_name| {
    # Using https://linux.dell.com as a file source caused some strange self-signed certificate error
    # with Puppet agent. The exec is a workaround for this.
    # I think this bug is due to https://tickets.puppetlabs.com/browse/PUP-7814.
    exec { "download Dell key ${key_name}":
      path    => '/bin:/usr/bin:/sbin:/usr/sbin',
      command => "curl -sSL https://linux.dell.com/repo/pgp_pubkeys/${key_name}.asc -o /usr/libexec/dell_dup/${key_name}.asc",
      creates => "/usr/libexec/dell_dup/${key_name}.asc",
      require => File['/usr/libexec/dell_dup'],
    }

    -> file { "/usr/libexec/dell_dup/${key_name}.asc":
      ensure => present,
      owner  => 'root',
      group  => 'root',
      mode   => '0644',
    }

    -> exec { "import gpg key ${key_name} into RPM":
      path      => '/bin:/usr/bin:/sbin:/usr/sbin',
      command   => "rpm --import /usr/libexec/dell_dup/${key_name}.asc",
      unless    => "rpm -qa | grep gpg-pubkey | grep -i ${key_name[-8, 8]}",
      logoutput => 'on_failure',
    }

    -> exec { "import gpg key ${key_name} into gpg":
      path      => '/bin:/usr/bin:/sbin:/usr/sbin',
      command   => "gpg --import /usr/libexec/dell_dup/${key_name}.asc",
      unless    => "gpg --list-keys ${key_name}",
      logoutput => 'on_failure',
    }
  }
}
