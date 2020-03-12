# @summary
#   This class handles kubeadm commands post Kubernetes installation, such as
#   cni network provider, scheduling on controller, etc.
#
# @api private
#
# @note MetalLB is only installed if all $metallb* parameters are set.
#
# @param cni_network_provider
#   The URL to apply for the CNI network provider.
# @param slate_tmp_dir
#   The temp dir to store the MetalLB config file.
# @param metallb_enabled
#   Installs MetalLB to the cluster. All other metallb* parameters must be set
#   for this.
# @param metallb_url
#   The URL of the MetalLB yaml file to apply using kubectl.
# @param metallb_start_ip_range
#   The first IP address that MetalLB can hand out.
# @param metallb_end_ip_range
#   The last IP address that MetalLB can hand out.
#
class slate::kubeadm::post (
  String $cni_network_provider,
  String $slate_tmp_dir = $slate::slate_tmp_dir,
  Boolean $metallb_enabled = true,
  Optional[String] $metallb_url,
  Optional[String] $metallb_start_ip_range,
  Optional[String] $metallb_end_ip_range,
) {
  $node_name = fact('networking.fqdn')

  exec { 'Install cni network provider':
    command     => "kubectl apply -f ${shell_escape($cni_network_provider)}",
    path        => ['/usr/bin', '/bin', '/sbin', '/usr/local/bin'],
    onlyif      => 'kubectl get nodes',
    unless      => "kubectl -n kube-system get daemonset | egrep '(flannel|weave|calico-node|cilium)'",
    environment => ['HOME=/root', 'KUBECONFIG=/etc/kubernetes/admin.conf'],
  }

  -> exec { 'schedule on controller':
    command     => "kubectl taint nodes ${node_name} node-role.kubernetes.io/master-",
    path        => ['/usr/bin', '/bin', '/sbin', '/usr/local/bin'],
    onlyif      => "kubectl describe nodes ${node_name} | tr -s ' ' | grep 'Taints: node-role.kubernetes.io/master:NoSchedule'",
    require     => Exec['kubeadm init'],
    environment => ['HOME=/root', 'KUBECONFIG=/etc/kubernetes/admin.conf'],
  }

  if $metallb_enabled {
    exec { 'apply metallb':
      command     => "kubectl apply -f ${shell_escape($metallb_url)}",
      path        => ['/usr/bin', '/bin', '/sbin', '/usr/local/bin'],
      onlyif      => 'kubectl get nodes',
      unless      => "kubectl -n kube-system get namespaces | egrep 'metallb'",
      environment => ['HOME=/root', 'KUBECONFIG=/etc/kubernetes/admin.conf'],
      require     => Exec['Install cni network provider'],
    }

    file { "${slate_tmp_dir}/metallb-config.yaml":
      require => File[$slate_tmp_dir],
      content => epp('slate/metallb-config.yaml.epp'),
    }
    ~> exec { 'apply metallb config':
      command     => "kubectl apply -f ${slate_tmp_dir}/metallb-config.yaml",
      path        => ['/usr/bin', '/bin', '/sbin', '/usr/local/bin'],
      onlyif      => 'kubectl get nodes',
      environment => ['HOME=/root', 'KUBECONFIG=/etc/kubernetes/admin.conf'],
      refreshonly => true,
      require     => Exec['apply metallb'],
    }
  }
}
