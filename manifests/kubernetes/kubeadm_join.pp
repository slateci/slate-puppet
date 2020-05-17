# @summary
#   This class handles the `kubeadm join` process for both controllers and workers.
#   If PuppetDB is used, the join tokens can be automatically discovered by nodes.
#
# @param config
#   A hash where each key is a configuration type that maps to a YAML-compatible hash to be passed to kubeadm join as a config file.
#   See data/common.yaml for an example.
#   See https://godoc.org/k8s.io/kubernetes/cmd/kubeadm/app/apis/kubeadm/v1beta2#hdr-Kubeadm_join_configuration_types
#   for all configuration settings. _Do not_ supply JoinConfiguration:nodeRegistration:name,
#   JoinConfiguration:discovery:bootstrapToken, or JoinConfiguration:controlPlane:certificateKey as these will be overridden
#   by other parameters.
#   Each configuration type must be present in config_versions. If some configuration values are not specified,
#   kubeadm will use default values for them.
# @param config_versions
#   A hash mapping each configuration type to its apiVersion.
# @param use_puppetdb
#   If true, automatically discover join tokens through PuppetDB. PuppetDB must be enabled on the Puppet Master.
#   If false, the `join_token` parameter will be used.
# @param join_tokens
#   The tokens to be used in the `kubeadm join` process. If `use_puppetdb` is false, this parameter must be specified.
#   `certificate_key` is only required for controller nodes.
# @param role
#   See $slate::kubernetes::role.
# @param controller_hostname
#   See $slate::kubernetes::controller_hostname.
# @param controller_port
#   See $slate::kubernetes::controller_port.
#
class slate::kubernetes::kubeadm_join (
  Hash[String, Hash] $config = {},
  Hash[String, String] $config_versions = {},
  Boolean $use_puppetdb = true,
  Optional[Struct[{
    certificate_key => Optional[String],
    discovery_token => String,
    discovery_ca_cert_hash => String,
  }]] $join_tokens,
  $role = $slate::kubernetes::role,
  $controller_hostname = $slate::kubernetes::controller_hostname,
  $controller_port = $slate::kubernetes::controller_port,
) {
  $node_name = fact('networking.fqdn')

  # Pull join tokens from PuppetDB.
  if $use_puppetdb {
    $pdb_join_tokens = puppetdb_query(epp('slate/join_tokens_query.epp', {
      'hostname' => $controller_hostname,
      'port' => $controller_port,
    }))

    if length($pdb_join_tokens) == 0 {
      fail(
        @("EOF"/L)
        Join tokens not found for ${controller_hostname}:${controller_port}. \
        The controller may not have published join tokens yet, if so, you will have to wait for the controller to make another Puppet run \
        before join tokens are available.
        | EOF
      )
    }

    else {
      $join_token = $pdb_join_tokens[0]['facts.slate.kubernetes']
    }
  }
  elsif $join_tokens == undef {
    fail('Join tokens were not provided with `use_puppetdb` set to false, cannot run `kubeadm join`...')
  }
  else {
    $join_token = $join_tokens
  }

  $base_config_ = {
    'JoinConfiguration' => {
      'nodeRegistration' => {
        'name' => $node_name
      },
      'discovery' => {
        'bootstrapToken' => {
          'token' => $join_token['discovery_token'],
          'caCertHashes' => ["sha256:${join_token['discovery_ca_cert_hash']}"],
          'apiServerEndpoint' => "${controller_hostname}:${controller_port}",
          'unsafeSkipCAVerification' => false,
        }
      },
    }
  }

  if $role == 'controller' {
    if $use_puppetdb and $join_token['control_plane_endpoint_hostname'] == undef {
      fail(
        @("EOF"/L)
        The cluster at ${controller_hostname}:${controller_port} was setup as a single-availability cluster \
        and does not support adding new controller nodes.
        | EOF
      )
    }

    if !$use_puppetdb and $join_token['certificate_key'] == undef {
      fail('A certificate key is needed in `join_token` for controllers.')
    }

    $base_config = deep_merge($base_config_, {
      'JoinConfiguration' => {
        'controlPlane' => {
          'certificateKey' => $join_token['certificate_key'],
        }
      }
    })

    notify { 'kubeadm join warning':
      message => @(EOF/L)
        All join tokens were found. Please be aware `kubeadm join` could fail as it is possible to be served a stale certificate key. \
        This is a transient error and should not be present in the next run. If this is a consistent failure, further investigation \
        is necessary.
        | EOF
    }
  }
  elsif $role == 'worker' {
    $base_config = $base_config_
  }

  file { '/etc/kubernetes/kubeadm-join.conf':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => epp('slate/kubeadm.conf.epp', { 'config' => deep_merge($config, $base_config), 'config_versions' => $config_versions })
  }
  -> exec { 'kubeadm join':
    command     => 'kubeadm join --config /etc/kubernetes/kubeadm-join.conf',
    environment => ['HOME=/root', 'KUBECONFIG=/etc/kubernetes/admin.conf'],
    path        => ['/usr/bin', '/bin', '/sbin', '/usr/local/bin'],
    logoutput   => true,
    timeout     => 0,
  }
}
