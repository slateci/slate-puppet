# slate
#
# Main class, includes all other classes.
#
# @param manage_kubernetes
#   Includes the slate::kubernetes class to setup Kubernetes on this node.
# @param register_with_slate
#   Install the SLATE CLI and register this cluster with SLATE.
# @param manage_slate_admin_accounts
#   Includes the slate::accounts class to create SLATE administrator accounts.
#
class slate (
  Boolean $manage_kubernetes = true,
  Boolean $register_with_slate = true,
  Boolean $manage_slate_admin_accounts = true,
) {
  contain slate::packages
  contain slate::tuning
  contain slate::security

  if $manage_kubernetes {
    contain slate::kubernetes

    $cluster_instantiating = $slate::kubernetes::role == 'initial_controller' and fact('slate.kubernetes.cluster_host') == undef

    if $register_with_slate and ($cluster_instantiating or fact('slate.kubernetes.leader')) {
      contain slate::registration

      class { 'slate::registration':
        require => [
          Class['slate::packages'],
          Class['slate::kubernetes'],
        ]
      }
    }
  }

  elsif $register_with_slate {
    contain slate::registration

    Class['slate::packages']
    -> Class['slate::registration']
  }

  if $manage_slate_admin_accounts {
    contain slate::accounts
  }
}
