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
  Optional[String] $metallb_url,
  Optional[String] $metallb_start_ip_range,
  Optional[String] $metallb_end_ip_range,
  Optional[String] $slate_client_token,
  Optional[String] $slate_cluster_name,
  Optional[String] $slate_group_name,
  Optional[String] $slate_org_name,
  Optional[String] $slate_loc_lat,
  Optional[String] $slate_loc_long,
  Optional[Accounts::User::Hash] $user_accounts,
  Optional[Accounts::User::Resource] $user_defaults,
  Optional[Array] $package_list = ['htop', 'strace', 'tmux', 'iftop', 'screen', 'sysstat', 'jq', 'curl'],
) {
  contain slate::packages
  contain slate::k8s_pre
  contain slate::k8s_post
  contain slate::api
  contain slate::accounts

  Class['slate::packages']
  -> Class['slate::k8s_pre']
  -> Class['slate::k8s_post']
  -> Class['slate::api']
}
