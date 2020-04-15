# slate
#
# Main class, includes all other classes.
#
# @param create_slate_admin_accounts
#   Includes slate::accounts class to create SLATE administrator accounts.
# @param single_node_cluster
#   Installs and configures Kubernetes as a single-node cluster. Do not enable
#   if you setup Kubernetes yourself or use puppetlabs-kubernetes.
# @param slate_tmp_dir
#   The directory to hold temporary SLATE files.
#
class slate (
  Boolean $create_slate_admin_accounts = true,
  Boolean $use_puppetlabs_kubernetes = false,
) {
  # TODO(emersonford): Ensure only the kube-scheduler master runs the SLATE registration.
  # if fact('slate.kubernetes.leader_acquire_time') ...
  contain slate::packages
  contain slate::tuning
  contain slate::security
  contain slate::registration

  Class['slate::packages']
  -> Class['slate::tuning']
  -> Class['slate::security']
  -> Class['slate::registration']

  if $use_puppetlabs_kubernetes {
    require kubernetes
  }
  else {
    contain slate::kubernetes

    Class['slate::kubernetes']
    -> Class['slate::registration']
  }

  if $create_slate_admin_accounts {
    contain slate::accounts
  }
}
