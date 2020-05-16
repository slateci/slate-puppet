# @summary
#   This class handles installing and updating Calico.
#
# @param manifest_url
#   URL for the Calico manifest.
class slate::kubernetes::cluster_management::calico (
  String $manifest_url,
) {
  # https://docs.projectcalico.org/maintenance/troubleshoot/troubleshooting#configure-networkmanager
  file { '/etc/NetworkManager/conf.d/calico.conf':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => "[keyfile]\nunmanaged-devices=interface-name:cali*;interface-name:tunl*"
  }

  # Allows us to restart NM on config change without managing the service.
  ~> exec { 'NetworkManager-system-reload':
    path        => '/bin',
    command     => 'systemctl is-active --quiet NetworkManager || exit 0; systemctl reload NetworkManager',
    refreshonly => true,
  }

  exec { 'Install/update cni network provider':
    command     => "kubectl apply -f ${shell_escape($manifest_url)}",
    path        => ['/usr/bin', '/bin', '/sbin', '/usr/local/bin'],
    unless      => "kubectl diff -f ${shell_escape($manifest_url)}",
    environment => ['HOME=/root', 'KUBECONFIG=/etc/kubernetes/admin.conf'],
  }
}
