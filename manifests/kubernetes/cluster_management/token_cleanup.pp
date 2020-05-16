# @summary
#   This class handles cleanup of kubeadm tokens.
#   This is necessary as our token facts generates new tokens quite frequently.
#
# @api private
#
class slate::kubernetes::cluster_management::token_cleanup {
  exec { 'cleanup invalid tokens':
    path        => ['/usr/bin', '/bin', '/sbin', '/usr/local/bin'],
    environment => ['HOME=/root', 'KUBECONFIG=/etc/kubernetes/admin.conf'],
    command     => @(EOF/L)
      kubeadm token list
      | tail -n +2
      | awk '{if($2 == "<invalid>") print $1;}'
      | xargs -n1 kubeadm token delete
      | - EOF
      ,
    onlyif      => @(EOF/L)
      test $(
      kubeadm token list
      | tail -n +2
      | awk '{if($2 == "<invalid>") print $1;}'
      | wc -l
      ) -ge 1
      | - EOF
      ,
  }
}
