# @summary
#   This class handles pre-Kubernetes installation steps such as disabling swap,
#   setting up kernel modules, etc.
#
# @param k8s_sysctl_path
#   The path to store k8s sysctl parameters.
#
class slate::kubernetes::pre (
  String $k8s_sysctl_path = '/etc/sysctl.d/k8s.conf',
) {
  exec { 'disable swap':
    path    => ['/usr/sbin', '/usr/bin', '/bin', '/sbin'],
    command => 'swapoff -a',
    unless  => "awk '{ if (NR > 1) exit 1}' /proc/swaps",
  }

  file_line { 'disable swap in /etc/fstab':
    ensure            => absent,
    path              => '/etc/fstab',
    match             => '.+\sswap\s.+',
    match_for_absence => true,
    multiple          => true,
  }

  # Set up the required sysctl configs and kernel modules.
  # https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#letting-iptables-see-bridged-traffic
  kmod::load { 'br_netfilter': }

  -> file { $k8s_sysctl_path:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => @(EOF/L)
    net.bridge.bridge-nf-call-ip6tables = 1
    net.bridge.bridge-nf-call-iptables = 1
    net.ipv4.ip_forward = 1
    net.ipv6.conf.all.forwarding = 1
    | - EOF
  }

  ~> exec { "refresh sysctl ${k8s_sysctl_path}":
    command     => "sysctl -p ${k8s_sysctl_path}",
    path        => ['/usr/bin', '/bin', '/sbin', '/usr/local/bin'],
    refreshonly => true,
  }
}
