# @summary
#   This class handles joining clusters, instantiating clusters, and settings for controller nodes.
#
# @param schedule_on_controller
#   See $slate::kubernetes::schedule_on_controller.
#
class slate::kubernetes::controller (
  $schedule_on_controller = $slate::kubernetes::schedule_on_controller,
) {
  $node_name = fact('networking.fqdn')

  $joined_to_cluster = fact('slate.kubernetes.cluster_host') != undef
  $cluster_instantiating = $slate::kubernetes::role == 'initial_controller' and !$joined_to_cluster

  file { '/etc/kubernetes/default-audit-policy.yaml':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0600',
    source => 'puppet:///modules/slate/default-audit-policy.yaml',
  }

  if $schedule_on_controller {
    exec { 'schedule on controller':
      command     => "kubectl taint nodes ${node_name} node-role.kubernetes.io/master-",
      path        => ['/usr/bin', '/bin', '/sbin', '/usr/local/bin'],
      onlyif      => "kubectl describe nodes ${node_name} | tr -s ' ' | grep 'Taints: node-role.kubernetes.io/master:NoSchedule'",
      environment => ['HOME=/root', 'KUBECONFIG=/etc/kubernetes/admin.conf'],
    }
  }
  else {
    exec { 'disable scheduling on controller':
      command     => "kubectl taint nodes ${node_name} node-role.kubernetes.io/master=:NoSchedule",
      path        => ['/usr/bin', '/bin', '/sbin', '/usr/local/bin'],
      unless      => "kubectl describe nodes ${node_name} | tr -s ' ' | grep 'Taints: node-role.kubernetes.io/master:NoSchedule'",
      environment => ['HOME=/root', 'KUBECONFIG=/etc/kubernetes/admin.conf'],
    }
  }

  if $cluster_instantiating or fact('slate.kubernetes.leader') {
    contain slate::kubernetes::cluster_management::calico
    contain slate::kubernetes::cluster_management::metallb
    contain slate::kubernetes::cluster_management::token_cleanup

    Class['slate::kubernetes::cluster_management::calico']
    -> Class['slate::kubernetes::cluster_management::metallb']

    if $cluster_instantiating {
      contain slate::kubernetes::cluster_init

      File['/etc/kubernetes/default-audit-policy.yaml']
      -> Class['slate::kubernetes::cluster_init']
      -> Class['slate::kubernetes::cluster_management::calico']

      Class['slate::kubernetes::cluster_init']
      -> Class['slate::kubernetes::cluster_management::token_cleanup']
    }
  }
  elsif !$joined_to_cluster {
    contain slate::kubernetes::kubeadm_join

    File['/etc/kubernetes/default-audit-policy.yaml']
    -> Class['slate::kubernetes::kubeadm_join']
  }
}
