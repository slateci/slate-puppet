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
  Boolean $single_node_cluster = true,
  String $slate_tmp_dir = '/tmp/slate',
) {
  if $single_node_cluster {
    contain slate::packages
    contain slate::tuning
    contain slate::security
    contain slate::kubeadm::packages
    contain slate::kubeadm::pre
    contain slate::kubeadm::run_init
    contain slate::kubeadm::post
    contain slate::registration

    Class['slate::packages']
    -> Class['slate::tuning']
    -> Class['slate::security']
    -> Class['slate::kubeadm::packages']
    -> Class['slate::kubeadm::pre']
    -> Class['slate::kubeadm::run_init']
    -> Class['slate::kubeadm::post']
    -> Class['slate::registration']
  }

  else {
    contain slate::packages
    contain slate::tuning
    contain slate::security
    contain slate::registration

    Class['slate::packages']
    -> Class['slate::tuning']
    -> Class['slate::security']
    -> Class['slate::registration']
  }

  if $create_slate_admin_accounts {
    contain slate::accounts
  }

}
