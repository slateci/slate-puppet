# slate
#
# Main class, includes all other classes.
#
# @param manage_kubernetes
#   Includes the slate::kubernetes class to setup Kubernetes on this node.
#   apply_security_policy must be set to true if this is set to true.
# @param register_with_slate
#   Install the SLATE CLI and register this cluster with SLATE.
# @param apply_security_policy
#   Applies the SLATE provided security policy. This will disable firewalld in favor of iptables.
#   This is required for manage_kubernetes.
# @param manage_slate_admin_accounts
#   Includes the slate::accounts class to manage SLATE administrator accounts.
#
class slate (
  Boolean $manage_kubernetes = true,
  Boolean $register_with_slate = true,
  Boolean $apply_security_policy = true,
  Boolean $manage_slate_admin_accounts = true,
) {
  if $facts['os']['family'] != 'RedHat' or $facts['os']['release']['major'] != '7' {
    fail('This module is only supported on RedHat 7/CentOS 7.')
  }

  contain slate::packages
  contain slate::tuning

  if $apply_security_policy {
    contain slate::security
  }

  if $manage_kubernetes {
    contain slate::kubernetes

    if !$apply_security_policy {
      fail('apply_security_policy must be set to true to manage Kubernetes.')
    }

    Class['slate::security']
    -> Class['slate::kubernetes']

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
