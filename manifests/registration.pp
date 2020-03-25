# @summary
#   This class handles SLATE cluster federation registration.
#
# @note This class requires the SLATE CLI to have been installed and present in
#   either '/usr', '/usr/bin', '/sbin', '/usr/local/bin'
#
# @param slate_client_token
#   The client token obtained for your user from the SLATE portal.
# @param slate_cluster_name
#   The name to register your cluster as.
# @param slate_group_name
#   The group name to register your cluster under.
# @param slate_org_name
#   The organization name to register your cluster under.
# @param slate_endpoint_url
#   The API endpoint for the SLATE CLI.
# @param ingress_enabled
#   Set to false if you do not have an ingress controller installed
#   on your Kubernetes cluster (e.g. MetalLB).
# @param slate_loc_lat
#   The latitude of your SLATE cluster location. Due to SLATE CLI limitations,
#   this is not fully declarative and is only run on the initial SLATE cluster registration.
# @param slate_loc_long
#   The longitude of your SLATE cluster location. Due to SLATE CLI limitations,
#   this is not fully declarative and is only run on the initial SLATE cluster registration.
#
class slate::registration (
  String $slate_client_token,
  String $slate_cluster_name,
  String $slate_group_name,
  String $slate_org_name,
  String $slate_endpoint_url = 'https://api.slateci.io:18080',
  Boolean $ingress_enabled = true,
  Optional[String] $slate_loc_lat,
  Optional[String] $slate_loc_long,
) {
  if $slate_client_token != undef {
    file { '/root/.slate':
      ensure => directory,
    }
    -> file { '/root/.slate/token':
      content => $slate_client_token,
      mode    => '0600',
    }
    -> file { '/root/.slate/endpoint':
      content => $slate_endpoint_url,
    }
  }

  $slate_flags = slate_create_flags({
    no_ingress => !$ingress_enabled,
    group      => $slate_group_name,
    org        => $slate_org_name,
    confirm    => true,
  })

  if $slate_cluster_name and $slate_group_name and $slate_org_name {
    exec { 'join SLATE federation':
      command     => "slate cluster create '${slate_cluster_name}' ${slate_flags}",
      path        => ['/usr/bin', '/bin', '/sbin', '/usr/local/bin'],
      # Ensure only the controller runs this command.
      onlyif      => 'kubectl get nodes $(hostname) | grep "master"',
      # TODO(emersonford): Use a better check for this unless.
      unless      => "slate cluster list | grep ${slate_cluster_name}",
      environment => ['HOME=/root', 'KUBECONFIG=/etc/kubernetes/admin.conf'],
      timeout     => 300,
      notify      => Exec['update cluster location'],
      require     => [
        File['/root/.slate/token'],
        File['/root/.slate/endpoint'],
      ],
    }

    if $slate_loc_lat and $slate_loc_long {
      # TODO(emersonford): Make this update declarative.
      exec { 'update cluster location':
        command     => "slate cluster update '${slate_cluster_name}' --location '${slate_loc_lat},${slate_loc_long}'",
        path        => ['/usr/bin', '/bin', '/sbin', '/usr/local/bin'],
        environment => ['HOME=/root', 'KUBECONFIG=/etc/kubernetes/admin.conf'],
        refreshonly => true,
      }
    }
  }
}
