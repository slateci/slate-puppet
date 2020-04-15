# @summary
#   This class handles kubeadm init.
#
# @api private
#
class slate::kubernetes::cluster_init (
  String $controller_hostname = $slate::kubernetes::controller_hostname,
  Integer[1, 65565] $controller_port = $slate::kubernetes::controller_port,
  Hash[Pattern[/\A[a-z_]+/], Variant[String, Boolean]] $kubeadm_init_flags = $slate::kubernetes::kubeadm_init_flags,
  String $cni_network_provider_url = $slate::kubernetes::cni_network_provider_url,
) {
  $node_name = fact('networking.fqdn')

  $init_flags = kubeadm_init_flags({
    node_name => $node_name,
    control_plane_endpoint => "${controller_hostname}:${controller_port}",
    upload_certs => true,
  } + $kubeadm_init_flags)

  exec { 'kubeadm init':
    command     => "kubeadm init ${init_flags}",
    environment => ['HOME=/root', 'KUBECONFIG=/etc/kubernetes/admin.conf'],
    path        => ['/usr/bin', '/bin', '/sbin', '/usr/local/bin'],
    logoutput   => true,
    timeout     => 0,
    unless      => "kubectl get nodes | grep ${node_name}",
  }

  -> exec { 'Install cni network provider':
    command     => "kubectl apply -f ${shell_escape($cni_network_provider_url)}",
    path        => ['/usr/bin', '/bin', '/sbin', '/usr/local/bin'],
    unless      => "kubectl -n kube-system get daemonset | egrep '(flannel|weave|calico-node|cilium)'",
    environment => ['HOME=/root', 'KUBECONFIG=/etc/kubernetes/admin.conf'],
  }
}
