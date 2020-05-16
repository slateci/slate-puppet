# @summary
#   This class handles managing worker nodes in the Kubernetes cluster.
#
class slate::kubernetes::worker {
  $node_name = fact('networking.fqdn')

  if fact('slate.kubernetes.cluster_host') == undef {
    contain slate::kubernetes::kubeadm_join
  }
}
