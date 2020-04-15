# @summary
#   This class handles settings for specific controller nodes.
#
# @api private
#
class slate::kubernetes::roles::controller (
  Boolean $schedule_on_controller = $slate::kubernetes::schedule_on_controller,
) {
  $node_name = fact('networking.fqdn')

  exec { 'schedule on controller':
    command     => "kubectl taint nodes ${node_name} node-role.kubernetes.io/master-",
    path        => ['/usr/bin', '/bin', '/sbin', '/usr/local/bin'],
    onlyif      => "kubectl describe nodes ${node_name} | tr -s ' ' | grep 'Taints: node-role.kubernetes.io/master:NoSchedule'",
    environment => ['HOME=/root', 'KUBECONFIG=/etc/kubernetes/admin.conf'],
  }

  # TODO(emersonford): Add check for leader then include cluster_cleanup.
}
