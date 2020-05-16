# @summary
#   This class handles setting security settings for Kubernetes, such as firewall settings and selinux modes.
#
# @note The firewall module will order rules starting with '000' to '899' before unmanaged rules.
#   Rules starting with '900' to '999' will be placed after unmanaged rules. This allows Calico's Fenix and
#   kube-proxy to manage their own rules independently of this module.
#
# @see https://github.com/puppetlabs/puppetlabs-firewall
#
#
# @param controller_ports
#   List of TCP ports to open for a controller node.
# @param general_ports
#   List of TCP ports to open for all k8s nodes.
# @param calico_ports
#   List of TCP ports to open for Calico on all k8s nodes.
# @param nodeport_services
#   List of TCP ports to open for NodePort Services for any node with scheduling enabled.
# @param role
#   See $slate::kubernetes::role
# @param schedule_on_controller
#   See $slate::kubernetes::schedule_on_controller
#
class slate::kubernetes::security (
  Array[String] $controller_ports,
  Array[String] $general_ports,
  Array[String] $calico_ports,
  Array[String] $nodeport_services,
  $role = $slate::kubernetes::role,
  $schedule_on_controller = $slate::kubernetes::schedule_on_controller,
) {
  # TODO(emersonf): Change this when this issue is resolved:
  # https://github.com/kubernetes/website/issues/14457
  class { 'selinux':
    mode => 'permissive',
  }

  # General Ports
  firewallchain { 'KUBE-GENERAL:filter:IPv4':
    ensure => present,
  }

  firewall { '100 check general k8s ports':
    proto => 'tcp',
    jump  => 'KUBE-GENERAL',
    chain => 'INPUT',
  }

  firewall { '100 accept general k8s ports':
    proto  => 'tcp',
    dport  => $general_ports,
    action => 'accept',
    state  => 'NEW',
    chain  => 'KUBE-GENERAL',
  }

  # Calico ports
  # Calico creates rules on its own to allow IP-in-IP so we don't need to create that rule.
  firewall { '101 accept calico ports':
    proto  => 'tcp',
    dport  => $calico_ports,
    action => 'accept',
    state  => 'NEW',
    chain  => 'KUBE-GENERAL',
  }

  # Nodeports
  firewallchain { 'KUBE-NODEPORT:filter:IPv4':
    ensure => present,
  }

  $enable_nodeports = ($role == 'worker' or $schedule_on_controller) ? {
    true    => present,
    default => absent,
  }

  firewall { '101 check k8s nodeports':
    ensure => $enable_nodeports,
    proto  => 'tcp',
    jump   => 'KUBE-NODEPORT',
    chain  => 'INPUT',
  }

  firewall { '100 accept k8s nodeports':
    ensure => $enable_nodeports,
    proto  => 'tcp',
    dport  => $nodeport_services,
    action => 'accept',
    state  => 'NEW',
    chain  => 'KUBE-NODEPORT',
  }

  # Controller ports
  # Roles shouldn't change so we can leave this as an imperative resource.
  if $role =~ /controller/ {
    firewallchain { 'KUBE-CONTROLLER:filter:IPv4':
      ensure => present,
    }

    firewall { '102 check controller k8s ports':
      proto => 'tcp',
      jump  => 'KUBE-CONTROLLER',
      chain => 'INPUT',
    }

    firewall { '100 accept controller k8s ports':
      proto  => 'tcp',
      dport  => $controller_ports,
      action => 'accept',
      state  => 'NEW',
      chain  => 'KUBE-CONTROLLER',
    }
  }
}
