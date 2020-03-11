# @summary
#   This class handles kubeadm init.
#
# @api private
#
class slate::kubeadm::run_init {
  $node_name = fact('networking.fqdn')

  service { 'kubelet':
    ensure  => running,
    enable  => true,
    require => Service['docker'],
  }

  -> exec { 'kubeadm init':
    command     => 'kubeadm init --pod-network-cidr=192.168.0.0/16',
    environment => ['HOME=/root', 'KUBECONFIG=/etc/kubernetes/admin.conf'],
    path        => ['/usr/bin', '/bin', '/sbin', '/usr/local/bin'],
    logoutput   => true,
    timeout     => 0,
    unless      => "kubectl get nodes | grep ${node_name}",
  }
}
