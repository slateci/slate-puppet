# @summary
#   This class handles kubeadm init.
#
# @param config
#   A hash where each key is a configuration type that maps to a YAML-compatible hash to be passed to kubeadm init as a config file.
#   See data/common.yaml for an example.
#   See https://godoc.org/k8s.io/kubernetes/cmd/kubeadm/app/apis/kubeadm/v1beta2#hdr-Kubeadm_init_configuration_types
#   for all configuration settings. _Do not_ supply InitConfiguration:nodeRegistration:name or
#   ClusterConfiguration:controlPlaneEndpoint as these will be overridden by other paramters.
#   Each configuration type must be present in config_versions. If some configuration values are not specified,
#   kubeadm will use default values for them.
# @param config_versions
#   A hash mapping each configuration type to its apiVersion.
# @param controller_hostname
#   See $slate::kubernetes::controller_hostname.
# @param controller_port
#   See $slate::kubernetes::controller_port.
#
class slate::kubernetes::kubeadm_init (
  Hash[String, Hash] $config = {},
  Hash[String, String] $config_versions = {},
  $controller_hostname = $slate::kubernetes::controller_hostname,
  $controller_port = $slate::kubernetes::controller_port,
) {
  $base_config = {
    'InitConfiguration' => {
      'nodeRegistration' => {
        'name' => fact('networking.fqdn')
      }
    },
    'ClusterConfiguration' => {
      'controlPlaneEndpoint' => "${controller_hostname}:${controller_port}"
    }
  }

  file { '/etc/kubernetes/kubeadm-init.conf':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => epp('slate/kubeadm.conf.epp', { 'config' => deep_merge($config, $base_config), 'config_versions' => $config_versions })
  }
  -> exec { 'kubeadm init':
    command     => 'kubeadm init --config /etc/kubernetes/kubeadm-init.conf',
    environment => ['HOME=/root', 'KUBECONFIG=/etc/kubernetes/admin.conf'],
    path        => ['/usr/bin', '/bin', '/sbin', '/usr/local/bin'],
    logoutput   => true,
    timeout     => 0,
  }
}
