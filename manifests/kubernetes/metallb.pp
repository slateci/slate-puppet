# @summary
#   This class handles installation of MetalLB on the cluster.
#
# @api private
#
class slate::kubernetes::metallb (
  String $namespace_url,
  String $manifest_url,
  String $start_ip_range,
  String $end_ip_range,
) {
  # TODO(emersonford): Allow for MetalLB upgrades.
  $metallb_config = epp('slate/metallb-config.yaml.epp', {
      'start_ip_range' => $start_ip_range,
      'end_ip_range' => $end_ip_range,
    }
  )

  exec { 'apply metallb namespace':
    command     => "kubectl apply -f ${shell_escape($namespace_url)}",
    path        => ['/usr/bin', '/bin', '/sbin', '/usr/local/bin'],
    onlyif      => 'kubectl get nodes',
    unless      => "kubectl -n kube-system get namespaces | egrep 'metallb'",
    environment => ['HOME=/root', 'KUBECONFIG=/etc/kubernetes/admin.conf'],
  }

  ~> exec { 'apply metallb manifest':
    command     => "kubectl apply -f ${shell_escape($manifest_url)}",
    path        => ['/usr/bin', '/bin', '/sbin', '/usr/local/bin'],
    environment => ['HOME=/root', 'KUBECONFIG=/etc/kubernetes/admin.conf'],
    refreshonly => true,
  }

  ~> exec { 'create metallb secrets':
    command     => 'kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"',
    path        => ['/usr/bin', '/bin', '/sbin', '/usr/local/bin'],
    environment => ['HOME=/root', 'KUBECONFIG=/etc/kubernetes/admin.conf'],
    refreshonly => true,
  }

  ~> exec { 'apply metallb config':
    command     => "kubectl apply -f - <<< '${metallb_config}'",
    path        => ['/usr/bin', '/bin', '/sbin', '/usr/local/bin'],
    # TODO(emersonford): Add some unless here to make it declarative, specifically we need to diff the config from above `kubectl get configmaps/config -n metallb-system -o yaml`.
    environment => ['HOME=/root', 'KUBECONFIG=/etc/kubernetes/admin.conf'],
    refreshonly => true,
  }
}
