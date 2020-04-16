# @summary
#   This class handles kubeadm commands post Kubernetes installation, such as
#   cni network provider, scheduling on controller, etc.
#
# @api private
#
class slate::kubernetes::kubeadm_join (
  Boolean $controller = $slate::kubernetes::controller,
  Boolean $worker = $slate::kubernetes::worker,
  String $controller_hostname = $slate::kubernetes::controller_hostname,
  Integer[1, 65565] $controller_port = $slate::kubernetes::controller_port,
  Hash[Pattern[/A[a-z_]+/], Variant[String, Boolean]] $kubeadm_join_flags = $slate::kubernetes::kubeadm_join_flags,
) {
  if $worker and $controller{
    fail('A node cannot both be a controller and a worker.')
  }

  # TODO(emersonford): Add parameters to manually specify these secrets for when someone doesn't
  # run PuppetDB.

  $join_tokens_query = @("EOF"/L)
    inventory[facts.slate.kubernetes]{
    facts.slate.kubernetes is not null
    and facts.slate.kubernetes.leader != false
    and (
      (
        facts.slate.kubernetes.apiserver_advertise_hostname is not null
        and facts.slate.kubernetes.apiserver_advertise_hostname = '${controller_hostname}'
        and facts.slate.kubernetes.apiserver_advertise_port = ${controller_port}
      )
      or
      (
        facts.slate.kubernetes.control_plane_endpoint_hostname is not null
        and facts.slate.kubernetes.control_plane_endpoint_hostname = '${controller_hostname}'
        and facts.slate.kubernetes.control_plane_endpoint_port = ${controller_port}
      )
    )
    order by timestamp asc
    }
    | - EOF
  $join_tokens = puppetdb_query($join_tokens_query)
  $node_name = fact('networking.fqdn')

  if length($join_tokens) == 0 {
    # TODO(emersonford): Improve logging here.
    notify { "Join tokens not found for ${controller_hostname}:${controller_port}. Ignoring kubeadm join until found...": }
  }
  elsif $controller or $worker {
    $join_token = $join_tokens[0]['facts.slate.kubernetes']

    if $controller {
      if $join_token['control_plane_endpoint_hostname'] == undef {
        fail(
          @(EOF)
          The cluster at ${controller_hostname}:${controller_port} was setup as a single-availability cluster
          and does not support adding new controller nodes.
          | -EOF
        )
      }

      $join_flags = kubeadm_join_flags({
        controller_address => "${controller_hostname}:${controller_port}",
        node_name => $node_name,
        control_plane => true,
        certificate_key => $join_token['certificate_key'],
        token => $join_token['discovery_token'],
        ca_cert_hash => $join_token['discovery_ca_cert_hash'],
      } + $kubeadm_join_flags)
    }

    elsif $worker {
      $join_flags = kubeadm_join_flags({
        controller_address => "${controller_hostname}:${controller_port}",
        node_name => $node_name,
        token => $join_token['discovery_token'],
        ca_cert_hash => $join_token['discovery_ca_cert_hash'],
      } + $kubeadm_join_flags)
    }

    exec { 'kubeadm join':
      command     => "kubeadm join ${join_flags}",
      environment => ['HOME=/root', 'KUBECONFIG=/etc/kubernetes/admin.conf'],
      path        => ['/usr/bin', '/bin', '/sbin', '/usr/local/bin'],
      logoutput   => true,
      timeout     => 0,
      # TODO(emersonford): Investigate better ways to detect if a worker is a part of a cluster.
      unless      => "cat /etc/kubernetes/kubelet.conf | grep '${controller_hostname}:${controller_port}'",
    }
  }
}
