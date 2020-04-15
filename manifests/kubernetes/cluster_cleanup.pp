# @summary
#   This class handles cleanup of kubeadm tokens.
#   This is necessary as our token facts generates new tokens quite frequently.
#
# @api private
#
class slate::kubernetes::cluster_cleanup {
  exec { 'cleanup old tokens':
    path        => ['/usr/bin', '/bin', '/sbin', '/usr/local/bin'],
    environment => ['HOME=/root', 'KUBECONFIG=/etc/kubernetes/admin.conf'],
    command     => @(EOF/L)
      set -euo pipefail;
      kubeadm token list
      | tail -n +2
      | awk -v date=$(date +%FT%T%:z --date="-7 days") '{if($2 == "<invalid>" && $3 < date) print $1;}'
      | xargs -n1 kubeadm token delete
      | - EOF
      ,
    onlyif      => @(EOF/L)
      set -euo pipefail;
      test $(
      kubeadm token list
      | tail -n +2
      | awk -v date=$(date +%FT%T%:z --date="-7 days") '{if($2 == "<invalid>" && $3 < date) print $1;}'
      | wc -l
      ) -ge 1
      | - EOF
      ,
  }
}
