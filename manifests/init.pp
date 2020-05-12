# slate
#
# Main class, includes all other classes.
#
# @param create_slate_admin_accounts
#   Includes the slate::accounts class to create SLATE administrator accounts.
# @param manage_kubernetes
#   Includes the slate::kubernetes class to setup Kubernetes on this node.
# @param register_with_slate
#   Install the SLATE CLI and register this cluster with SLATE.
#
class slate (
  Boolean $create_slate_admin_accounts = true,
  Boolean $manage_kubernetes = true,
  Boolean $register_with_slate = true,
) {
  # TODO(emersonford): Ensure only the kube-scheduler master runs the SLATE registration.
  # if fact('slate.kubernetes.leader_acquire_time') ...
  contain slate::packages
  contain slate::tuning
  contain slate::security

  Class['slate::packages']
  -> Class['slate::tuning']
  -> Class['slate::security']

  if $register_with_slate {
    contain slate::registration

    Class['slate::packages']
    -> Class['slate::registration']
  }

  if $manage_kubernetes {
    contain slate::kubernetes

    Class['slate::security']
    -> Class['slate::kubernetes']

    if $register_with_slate {
      Class['slate::kubernetes']
      -> Class['slate::registration']
    }
  }

  if $create_slate_admin_accounts {
    contain slate::accounts
  }
}
