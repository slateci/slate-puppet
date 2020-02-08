# @summary
#   This class handles SLATE CLI installation and cluster federation.
#
# @api private
class slate::api () {
  if $slate::slate_client_token != undef {
    file { '/root/.slate':
      ensure => directory,
    }
    -> file { '/root/.slate/token':
      content => $slate::slate_client_token,
      mode    => '0600',
    }
    -> file { '/root/.slate/endpoint':
      content => $slate::slate_endpoint_url,
    }
  }


  if $slate::slate_cluster_name != undef and $slate::slate_group_name != undef and $slate::slate_org_name != undef {
    exec { 'join SLATE federation':
      command     => "slate cluster create '${slate::slate_cluster_name}' --group '${slate::slate_group_name}' \
      --org '${slate::slate_org_name}' -y",
      path        => ['/usr/bin', '/bin', '/sbin', '/usr/local/bin'],
      onlyif      => 'kubectl get nodes',
      unless      => "slate cluster list | grep ${slate::slate_cluster_name}",
      environment => ['HOME=/root', 'KUBECONFIG=/etc/kubernetes/admin.conf'],
      notify      => Exec['update cluster location'],
      require     => [
        File['/root/.slate/token'],
        File['/root/.slate/endpoint'],
      ],
    }

    if $slate::slate_loc_lat != undef and $slate::slate_loc_long != undef {
      exec { 'update cluster location':
        command     => "slate cluster update '${slate::slate_cluster_name}' --location '${slate::slate_loc_lat},${slate::slate_loc_long}'",
        path        => ['/usr/bin', '/bin', '/sbin', '/usr/local/bin'],
        environment => ['HOME=/root', 'KUBECONFIG=/etc/kubernetes/admin.conf'],
        refreshonly => true,
      }
    }
  }
}
