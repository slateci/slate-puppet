require 'json'
require 'yaml'
require 'English'

# NOTE: This fact has side-effects on the Kubernetes system.
# It will generate discovery tokens and certificate keys.
Facter.add(:slate) do
  kubectl_config = '/etc/kubernetes/admin.conf'
  kubelet_config = '/etc/kubernetes/kubelet.conf'
  kubectl = "kubectl --kubeconfig='#{kubectl_config}'"
  kubeadm = 'kubeadm'
  res = {}

  Facter::Core::Execution.execute('systemctl is-active --quiet kubelet')
  return unless $CHILD_STATUS.exitstatus.zero?
  return unless File.exist?(kubelet_config)

  # Grab information about kubelet.
  kubelet_ver = Facter::Core::Execution.execute('kubelet --version')

  kubelet_yaml = YAML.safe_load(File.read(kubelet_config))
  return if kubelet_yaml['clusters'].empty?
  cluster_host, cluster_port = kubelet_yaml['clusters'][0]['cluster']['server'].match(%r{https://(.+):(.+)})[1, 2]

  # This also allows us to check if a node has been joined to a cluster.
  # If `fact('slate.kubernetes.kubelet_cluster_host') == undef` then the node has not been joined to a cluster.
  res['kubernetes'] = {
    'kubelet_version'      => kubelet_ver.match(%r{Kubernetes v([0-9.]+)})[1],
    'kubelet_cluster_host' => cluster_host,
    'kubelet_cluster_port' => cluster_port,
  }

  # Check if we have kubeadm installed here.
  Facter::Core::Execution.execute('yum list installed | grep kubeadm')
  if $CHILD_STATUS.exitstatus != 0
    setcode do
      res
    end
    return
  end

  kubeadm_ver = Facter::Core::Execution.execute('kubeadm version -o short')
  res['kubernetes']['kubeadm_version'] = kubeadm_ver.match(%r{v([0-9.]+)})[1]

  # Check if we have kubectl installed here.
  Facter::Core::Execution.execute('yum list installed | grep kubectl')
  if $CHILD_STATUS.exitstatus != 0
    setcode do
      res
    end
    return
  end

  Facter::Core::Execution.execute("#{kubectl} get nodes")
  if $CHILD_STATUS.exitstatus != 0
    setcode do
      res
    end
    return
  end

  hostname = Facter.value(:networking)['fqdn']
  leader_info_json = Facter::Core::Execution.execute("#{kubectl} get ep/kube-scheduler -n kube-system -o json")
  leader_info = JSON.parse(JSON.parse(leader_info_json)['metadata']['annotations']['control-plane.alpha.kubernetes.io/leader'])

  # We want to prevent multiple hosts from creating new certificate keys, creating
  # race conditions when bringing up new control nodes. This ensures only the current
  # kube-scheduler leader creates certificate keys. It's not fool-proof in avoiding
  # race conditions, but it's good enough.
  #
  # If Kubernetes makes it possible to determine when a certificate key is still valid,
  # this can probably be removed. For now, it's impossible to determine what the TTL
  # of a given certificate key is.
  #
  # Removes the tag beginning with _ from the holderIdentity string to get the hostname.
  if hostname != leader_info['holderIdentity'].scan(%r{(.+)(_[a-z0-9-]+)})[0][0]
    res['kubernetes']['leader'] = false
    setcode do
      res
    end
    return
  else
    res['kubernetes']['leader'] = true
  end

  # We can't keep track of which certificate keys are still valid, so we generate a new one each time.
  certificate_key = Facter::Core::Execution.execute("#{kubeadm} init phase upload-certs --upload-certs 2>/dev/null | egrep '^\\w{64}$'")

  # Source: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#join-nodes
  discovery_ca_cert_hash = Facter::Core::Execution.execute("openssl x509 -in /etc/kubernetes/pki/ca.crt -noout -pubkey | openssl rsa -pubin -outform DER 2>/dev/null | sha256sum | cut -d' ' -f1")

  discovery_tokens = Facter::Core::Execution.execute("#{kubeadm} token list | grep 'authentication,signing'")

  discovery_token = ''

  # Check if we already have a valid discovery token to pass out.
  discovery_tokens.each_line do |line|
    token, ttl = line.split(' ')
    if ttl =~ %r{\d+h}
      discovery_token = token
      break
    end
  end

  # If not, generate a new one.
  if discovery_token == ''
    discovery_token = Facter::Core::Execution.execute("#{kubeadm} token create")
  end

  res['kubernetes'] = res['kubernetes'].merge(
    'certificate_key' => certificate_key,
    'discovery_ca_cert_hash' => discovery_ca_cert_hash,
    'discovery_token' => discovery_token,
    'leader_acquire_time' => leader_info['acquireTime'],
  )

  # Publish our control_plane_endpoint or apiserver_advertise_address.
  kubeadm_config_json = Facter::Core::Execution.execute("#{kubectl} get configmap/kubeadm-config -n kube-system -o json")
  kubeadm_config = JSON.parse(kubeadm_config_json)

  cluster_status = YAML.safe_load(kubeadm_config['data']['ClusterStatus'])
  cluster_config = YAML.safe_load(kubeadm_config['data']['ClusterConfiguration'])

  # Only present on a cluster set up as a high-availability cluster.
  if cluster_config.key?('controlPlaneEndpoint')
    cpe = cluster_config['controlPlaneEndpoint'].split(':')
    res['kubernetes'] = res['kubernetes'].merge(
      'control_plane_endpoint_hostname' => cpe[0],
      'control_plane_endpoint_port' => cpe[1].to_i,
    )

  # The cluster is a single availability cluster.
  else
    cluster_status['apiEndpoints'].each_pair do |api_hostname, value|
      res['kubernetes'] = res['kubernetes'].merge(
        'apiserver_advertise_hostname' => api_hostname,
        'apiserver_advertise_address' => value['advertiseAddress'],
        'apiserver_advertise_port' => value['bindPort'].to_i,
      )
      break
    end
  end

  setcode do
    res
  end
end
