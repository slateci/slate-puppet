# slate
#
# Main class, includes all other classes.
#
class slate (
  String $k8s_version,
  String $docker_version,
  String $cni_network_provider,
  String $slate_tmp_dir = '/tmp/slate',
  String $slate_endpoint_url = 'https://api.slateci.io:18080',
  Boolean $disable_root_ssh = true,
  Boolean $kube_schedule_on_controller = true,
  Boolean $create_slate_admin_accounts = true,
  Boolean $install_dell_racadm = true,
  Optional[String] $metallb_url,
  Optional[String] $metallb_start_ip_range,
  Optional[String] $metallb_end_ip_range,
  Optional[String] $slate_client_token,
  Optional[String] $slate_cluster_name,
  Optional[String] $slate_group_name,
  Optional[String] $slate_org_name,
  Optional[String] $slate_loc_lat,
  Optional[String] $slate_loc_long,
  Array $package_list = ['htop', 'strace', 'tmux', 'iftop', 'screen', 'sysstat', 'jq', 'curl'],
) {
  contain slate::packages
  contain slate::kubeadm_pre
  contain slate::kubeadm_init
  contain slate::kubeadm_post
  contain slate::api

  if $slate::create_slate_admin_accounts {
    contain slate::accounts
  }

  Class['slate::packages']
  -> Class['slate::kubeadm_pre']
  -> Class['slate::kubeadm_init']
  -> Class['slate::kubeadm_post']
  -> Class['slate::api']
}
