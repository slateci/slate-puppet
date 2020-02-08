# @summary
#   This class handles k8s installation.
#
# @api private
class slate::k8s_post () {
  $node_name = fact('networking.fqdn')

  service { 'kubelet':
    ensure => running,
    enable => true,
  }

  exec { 'kubeadm init':
    command     => 'kubeadm init --pod-network-cidr=192.168.0.0/16',
    environment => ['HOME=/root', 'KUBECONFIG=/etc/kubernetes/admin.conf'],
    path        => ['/usr/bin', '/bin', '/sbin', '/usr/local/bin'],
    logoutput   => true,
    timeout     => 0,
    unless      => "kubectl get nodes | grep ${node_name}",
    require     => Service['kubelet'],
  }

  exec { 'schedule on controller':
    command => "kubectl taint nodes ${node_name} node-role.kubernetes.io/master-",
    path    => ['/usr/bin', '/bin', '/sbin', '/usr/local/bin'],
    onlyif  => "kubectl describe nodes ${node_name} | tr -s ' ' | grep 'Taints: node-role.kubernetes.io/master:NoSchedule'",
  }

  $shellsafe_provider = shell_escape($slate::cni_network_provider)
  exec { 'Install cni network provider':
    command     => "kubectl apply -f ${shellsafe_provider}",
    path        => ['/usr/bin', '/bin', '/sbin', '/usr/local/bin'],
    onlyif      => 'kubectl get nodes',
    unless      => "kubectl -n kube-system get daemonset | egrep '(flannel|weave|calico-node|cilium)'",
    environment => ['HOME=/root', 'KUBECONFIG=/etc/kubernetes/admin.conf'],
  }

  if $slate::metallb_start_ip_range != undef and $slate::metallb_end_ip_range != undef and $slate::metallb_url != undef{
    $shellsafe_provider = shell_escape($slate::metallb_url)
    exec { 'apply metallb':
      command     => "kubectl apply -f ${shellsafe_provider}",
      path        => ['/usr/bin', '/bin', '/sbin', '/usr/local/bin'],
      onlyif      => 'kubectl get nodes',
      unless      => "kubectl -n kube-system get daemonset | egrep 'metallb'",
      environment => ['HOME=/root', 'KUBECONFIG=/etc/kubernetes/admin.conf'],
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
    }
  }
}
