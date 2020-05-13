# @summary
#   This class handles SLATE cluster federation registration.
#
# @note This class requires /etc/kubernetes/admin.conf to be present.
#
# @note Requires the SLATE CLI to be installed in /usr/local/bin.
#   With the endpoint file and client token file present in /root/.slate.
#   This can be accomplished with the slate::cli class.
#
# @param slate_cluster_name
#   The name to register your cluster as.
# @param slate_group_name
#   The group name to register your cluster under.
# @param slate_org_name
#   The organization name to register your cluster under.
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
  String $slate_cluster_name,
  String $slate_group_name,
  String $slate_org_name,
  Boolean $ingress_enabled = true,
  Optional[String] $slate_loc_lat,
  Optional[String] $slate_loc_long,
) {
  # TODO(emersonford): Make registration declarative, i.e. if registration is set to false
  # we delete the cluster from SLATE.

  $slate_flags = slate_create_flags({
    no_ingress => !$ingress_enabled,
    group      => $slate_group_name,
    org        => $slate_org_name,
    confirm    => true,
  })

  if $slate_cluster_name and $slate_group_name and $slate_org_name {
    exec { 'check kubectl is working':
      command     => 'test -f /etc/kubernetes/admin.conf && kubectl get nodes',
      path        => ['/usr/bin', '/bin', '/sbin', '/usr/local/bin'],
      environment => ['HOME=/root', 'KUBECONFIG=/etc/kubernetes/admin.conf'],
    }

    -> exec { 'join SLATE federation':
      command     => "slate cluster create '${slate_cluster_name}' ${slate_flags}",
      path        => ['/usr/bin', '/bin', '/sbin', '/usr/local/bin'],
      # TODO(emersonford): Use a better check for this unless.
      unless      => "slate cluster list | grep ${slate_cluster_name}",
      environment => ['HOME=/root', 'KUBECONFIG=/etc/kubernetes/admin.conf'],
      timeout     => 300,
      notify      => Exec['update cluster location'],
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
