# @summary
#   This class handles setting security settings for Kubernetes.
#
#
class slate::kubernetes::security (
) {
  # TODO(emersonf): Change this when this issue is resolved:
  # https://github.com/kubernetes/website/issues/14457
  class { 'selinux':
    mode => 'permissive',
  }

  # TODO(emersonf): Change this to a specific port list.
  class { 'firewalld':
    service_enable => false,
    service_ensure => stopped,
  }
}
