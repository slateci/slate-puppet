# @summary
#   This class handles installation and updates to MetalLB on the cluster..
#   Updates to the MetalLB config will be applied to the cluster.
#
# @note Only MetalLB version v0.9.X is currently supported by this module.
#
# @param namespace_url
#   The URL that contains the YAML config to setup the MetalLB namespace.
# @param manifest_url
#   The URL that contains the YAML config to setup MetalLB itself.
# @param start_ip_range
#   The starting IP to use for MetalLB load balancing.
# @param end_ip_range
#   The ending IP to use for MetalLB load balancing.
#
class slate::kubernetes::metallb (
  String $namespace_url,
  String $manifest_url,
  String $start_ip_range,
  String $end_ip_range,
) {
  $metallb_config = epp('slate/metallb-config.yaml.epp', {
      'start_ip_range' => $start_ip_range,
      'end_ip_range' => $end_ip_range,
    }
  )

  exec { 'apply metallb namespace':
    command     => "kubectl apply -f ${shell_escape($namespace_url)}",
    path        => ['/usr/bin', '/bin', '/sbin', '/usr/local/bin'],
    onlyif      => 'kubectl get nodes',
    unless      => "kubectl diff -f ${shell_escape($namespace_url)}",
    environment => ['HOME=/root', 'KUBECONFIG=/etc/kubernetes/admin.conf'],
  }

  -> exec { 'apply metallb manifest':
    command     => "kubectl apply -f ${shell_escape($manifest_url)}",
    path        => ['/usr/bin', '/bin', '/sbin', '/usr/local/bin'],
    environment => ['HOME=/root', 'KUBECONFIG=/etc/kubernetes/admin.conf'],
    unless      => "kubectl diff -f ${shell_escape($manifest_url)}",
  }

  -> exec { 'create metallb secrets':
    command     => 'kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"',
    path        => ['/usr/bin', '/bin', '/sbin', '/usr/local/bin'],
    environment => ['HOME=/root', 'KUBECONFIG=/etc/kubernetes/admin.conf'],
    unless      => 'test "$(kubectl get secrets -n metallb-system 2>&1)" != "No resources found."',
  }

  -> exec { 'apply metallb config':
    command     => "kubectl apply -f - <<< '${metallb_config}'",
    path        => ['/usr/bin', '/bin', '/sbin', '/usr/local/bin'],
    environment => ['HOME=/root', 'KUBECONFIG=/etc/kubernetes/admin.conf'],
    unless      => "kubectl diff -f - <<< '${metallb_config}'",
  }
}
