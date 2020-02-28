# @summary
#   This class handles k8s installation.
#
# @api private
class slate::kubeadm_post (
  $metallb_enabled = $slate::metallb_start_ip_range != undef and $slate::metallb_end_ip_range != undef and $slate::metallb_url != undef,
) {
  $node_name = fact('networking.fqdn')

  exec { 'Install cni network provider':
    command     => "kubectl apply -f ${shell_escape($slate::cni_network_provider)}",
    path        => ['/usr/bin', '/bin', '/sbin', '/usr/local/bin'],
    onlyif      => 'kubectl get nodes',
    unless      => "kubectl -n kube-system get daemonset | egrep '(flannel|weave|calico-node|cilium)'",
    environment => ['HOME=/root', 'KUBECONFIG=/etc/kubernetes/admin.conf'],
  }

  if $slate::kube_schedule_on_controller {
    exec { 'schedule on controller':
      command     => "kubectl taint nodes ${node_name} node-role.kubernetes.io/master-",
      path        => ['/usr/bin', '/bin', '/sbin', '/usr/local/bin'],
      onlyif      => "kubectl describe nodes ${node_name} | tr -s ' ' | grep 'Taints: node-role.kubernetes.io/master:NoSchedule'",
      require     => Exec['kubeadm init'],
      environment => ['HOME=/root', 'KUBECONFIG=/etc/kubernetes/admin.conf'],
    }
  }

  if $metallb_enabled {
    exec { 'apply metallb':
      command     => "kubectl apply -f ${shell_escape($slate::metallb_url)}",
      path        => ['/usr/bin', '/bin', '/sbin', '/usr/local/bin'],
      onlyif      => 'kubectl get nodes',
      unless      => "kubectl -n kube-system get namespaces | egrep 'metallb'",
      environment => ['HOME=/root', 'KUBECONFIG=/etc/kubernetes/admin.conf'],
      require     => Exec['Install cni network provider'],
    }
    -> file { 'metallb-config.yaml':
      path    => "${slate::slate_tmp_dir}/metallb-config.yaml",
      require => File[$slate::slate_tmp_dir],
      content => epp('slate/metallb-config.yaml.epp'),
    }
    ~> exec { 'apply metallb config':
      command     => "kubectl apply -f ${slate::slate_tmp_dir}/metallb-config.yaml",
      path        => ['/usr/bin', '/bin', '/sbin', '/usr/local/bin'],
      onlyif      => 'kubectl get nodes',
      environment => ['HOME=/root', 'KUBECONFIG=/etc/kubernetes/admin.conf'],
      refreshonly => true,
    }
  }
}
