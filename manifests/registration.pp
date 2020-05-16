# @summary
#   This class handles SLATE cluster federation registration.
#
# @note This class requires /etc/kubernetes/admin.conf to be present.
#
# @note Requires the SLATE CLI to be installed in /usr/local/bin.
#   With the endpoint file present in /root/.slate.
#   This can be accomplished by requiring the slate::cli class.
#
# @param client_token
#   The client token obtained for your user from the SLATE portal.
# @param cluster_name
#   The name to register your cluster as.
# @param group_name
#   The group name to register your cluster under.
# @param org_name
#   The organization name to register your cluster under.
# @param cluster_location
#   The location of your cluster, the string should be of the form "[LATTITUDE],[LONGITUDE]".
#   Due to SLATE CLI limitations, this is not fully declarative and is only run on the initial SLATE cluster registration.
# @param ingress_enabled
#   Set to false if you do not have an ingress controller installed
#   on your Kubernetes cluster (e.g. MetalLB).
#
class slate::registration (
  String $client_token,
  String $cluster_name,
  String $group_name,
  String $org_name,
  Optional[String] $cluster_location,
  Boolean $ingress_enabled = true,
) {
  # TODO(emersonford): Make registration declarative, i.e. if registration is set to false
  # we delete the cluster from SLATE.

  $cli_flags = slate_create_flags({
    no_ingress => !$ingress_enabled,
    group      => $group_name,
    org        => $org_name,
    confirm    => true,
  })

  file { '/root/.slate/token':
    content => $client_token,
    mode    => '0600',
  }

  # This will fail if kubectl is not working, providing feedback as to why SLATE cluster creation
  # may not be working.
  exec { 'check kubectl is working':
      command     => 'test -f /etc/kubernetes/admin.conf && kubectl get nodes',
      path        => ['/usr/bin', '/bin', '/sbin', '/usr/local/bin'],
      environment => ['HOME=/root', 'KUBECONFIG=/etc/kubernetes/admin.conf'],
  }

  -> exec { 'join SLATE federation':
    command     => "slate cluster create '${cluster_name}' ${cli_flags}",
    path        => ['/usr/bin', '/bin', '/sbin', '/usr/local/bin'],
    # TODO(emersonford): Use a better check for this unless.
    unless      => "slate cluster list | grep ${cluster_name}",
    environment => ['HOME=/root', 'KUBECONFIG=/etc/kubernetes/admin.conf'],
    timeout     => 300,
    notify      => Exec['update cluster location'],
    require     => File['/root/.slate/token'],
  }

  if $cluster_location {
    # TODO(emersonford): Make this update declarative.
    exec { 'update cluster location':
      command     => "slate cluster update '${cluster_name}' --location '${cluster_location}'",
      path        => ['/usr/bin', '/bin', '/sbin', '/usr/local/bin'],
      environment => ['HOME=/root', 'KUBECONFIG=/etc/kubernetes/admin.conf'],
      refreshonly => true,
    }
  }
}
