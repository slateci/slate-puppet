# @summary
#   This class handles disabling cloud-init.
#
class slate::cloudinit {
  $node_name = fact('networking.fqdn')

  # From: https://askubuntu.com/questions/1028633/host-name-reverts-to-old-name-after-reboot-in-18-04-lts
  file { '/etc/cloud/cloud-init.disabled':
    ensure =>  present,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  file_line { 'preserve_hostname':
    ensure => present,
    path   => '/etc/cloud/cloud.cfg',
    line   => 'preserve_hostname: true',
    match  => '^preserve_hostname:[\w ]*$',
  }

  exec { 'set hostname':
    command => "hostnamectl set-hostname ${node_name}",
    unless  => "test $(hostnamectl status | awk -F': ' 'NR==1{print \$2}') = ${node_name}",
    path    => ['/usr/bin', '/bin', '/sbin', '/usr/local/bin'],
  }
}
