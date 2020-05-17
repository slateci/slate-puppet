# slate-puppet

A Puppet module to manage nodes as part of SLATE. Can handles instantiation and joining of nodes to Kubernetes cluster for SLATE purposes and registration with SLATE.

#### Table of Contents

1. [Description](#description)
2. [Setup](#setup)
    * [What slate-puppet affects](#what-slate-puppet-affects)
    * [Requirements](#requirements)
    * [Installation](#installation)
3. [Usage](#usage)
    * [Default (multi-master/multi-worker with no existing cluster)](#default-multi-mastermulti-worker-with-no-existing-cluster)
    * [Single Node Cluster](#single-node-cluster)
    * [Existing Cluster](#existing-cluster)
    * [Picking and Choosing Settings](#picking-and-choosing-settings)
4. [How Do I?](#how-do-i)
    * [Change podSubnet, serviceSubnet, etc](#change-podsubnet-servicesubnet-etc)
5. [Limitations](#limitations)

## Description

This module can handle:
* Creation and management of SLATE admin accounts
* Installation of SLATE CLI and packages
* Application of SLATE security policy
* Deployment of Kubernetes
* Deployment/joining of new nodes to an existing Kubernetes cluster
* Registration of Kubernetes cluster with SLATE

The Kubernetes cluster that is deployed with this module is a high-availability, stacked etcd, almost CIS compliant cluster with a standard audit policy that uses Calico as its CNI and MetalLB as its load balancer. All instantiation and and joining of new nodes is done through `kubeadm`.

This modules supports management of existing clusters, thereby allowing new nodes to be easily added to existing clusters.

It is designed to be highly modular where nearly all modules could be included independently of one another.
Thus, this module could be used solely to bring up a Kubernetes cluster, or used solely to register an existing cluster with SLATE.

This module uses Hiera extensively, nearly all parameters must be passed in through Hiera.
See `data/slate.yaml` for the default SLATE specific Hiera parameters and `data/kubernetes.yaml` for the default Kubernetes specific Hiera parameters.

## Setup

### What slate-puppet affects

Please see REFERENCES.md for a description of each class.

This module, by default, will manage things such as:
* Firewalls (disabling `firewalld` for `iptables`)
* `sysctl` parameters
* Kernel modules
* SLATE admin accounts
* SLATE cluster registration
* Per-node Kubernetes installation/management

### Requirements

This module only supports CentOS 7. All nodes must be running CentOS 7.

In order to have automatic join token discovery functioning, PuppetDB must be installed with your Puppet Master (see https://puppet.com/docs/puppetdb/latest/index.html). If PuppetDB is not installed, the following Hiera parameters are required to join new nodes to an existing cluster:
```
slate::kubernetes::kubeadm_join::use_puppetdb: false
slate::kubernetes::kubeadm_join::join_tokens:
# certificateKey is only needed for controller node joining.
  certificateKey: ''
  discovery_token: ''
  discovery_ca_cert_hash: ''
```
These can be obtained by following the guide on https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#join-nodes.

### Installation

To install, find the most recent package release at https://github.com/slateci/slate-puppet/releases, download it, and run `puppet module install slate-slate-VER.tar.gz` on your Puppet Master.

## Usage

Please see REFERENCES.md for an explanation of each Hiera parameter.
Please see `data/*.yaml` for defaults of each Hiera parameter.

It is _highly_ recommended that the
```
slate::kubernetes::docker_version:
slate::kubernetes::kubernetes_version:
slate::kubernetes::cluster_management::metallb::namespace_url:
slate::kubernetes::cluster_management::metallb::manifest_url:
slate::kubernetes::cluster_management::calico::manifest_url:
```
Hiera parameters are set on a _per node_ basis to avoid accidental package/manifest upgrades. See REFERENCES.md for an explanation why.

This module can be used in variety of scenarios:

### Default (multi-master/multi-worker with no existing cluster)
By default, this module will instantiate a Kubernetes cluster, apply a security policy to each node (e.g. firewall management), create SLATE admin accounts, and register the new Kubernetes cluster to SLATE.

For all nodes, `include slate` for that node through a method such as `site.pp` or an ENC. Then, the following Hiera parameters must be specified:
```
slate::kubernetes::role: '[ROLE]'
slate::kubernetes::controller_hostname: '[CONTROLLER_HOSTNAME]'
```
Where `[ROLE]` can be either `initial_controller`, `controller`, or `worker`. All non `initial_controller` must have the same `[CONTROLLER_HOSTNAME]` as the `initial_controller`. One node must be set as the `initial_controller`. On that node, the `[CONTROLLER_HOSTNAME]` will specify the hostname for the entire cluster. See `slate::kubernetes::controller_hostname` for details.

On all controllers, the following Hiera parameters must be specified:
```
slate::registration::client_token: '[CLIENT_TOKEN]'
slate::registration::cluster_name: '[CLUSTER_NAME]'
slate::registration::group_name: '[GROUP_NAME]'
slate::registration::org_name: '[ORG_NAME]'
slate::registration::cluster_location: '[CLUSTER_LOCATION]'

slate::kubernetes::cluster_management::metallb::config:
  address-pools:
  - name: default
    protocol: layer2
    addresses:
    - '[START_IP]-[END_IP]'
```
Where each `[]` indicates information you must specify. See REFERENCES.md for information about each parameter.

If PuppetDB is used, join tokens will be automatically discovered. Note, the first run of `kubeadm join` may fail as it takes two Puppet agent runs on the controller nodes to share join tokens. If PuppetDB is not used, the parameters specified in 'Setup Requirements' are necessary.

### Single Node Cluster

For a single node cluster, include `slate` on that node and use the following Hiera parameters:
```
slate::registration::client_token: '[CLIENT_TOKEN]'
slate::registration::cluster_name: "%{networking.fqdn}"
slate::registration::group_name: '[GROUP_NAME]'
slate::registration::org_name: '[ORG_NAME]'
slate::registration::cluster_location: '[CLUSTER_LOCATION]'

slate::kubernetes::role: 'initial_controller'
slate::kubernetes::controller_hostname: "%{networking.fqdn}"
slate::kubernetes::cluster_management::metallb::config:
  address-pools:
  - name: default
    protocol: layer2
    addresses:
    - "%{networking.ip}/32"
```
Where each `[]` indicates information you must specify. See REFERENCES.md for information about each parameter.

### Existing Cluster

include `slate` on all node in the cluster and follow the instructions specified in 'Default'.
An `initial_controller` is not needed with an existing cluster.

### Picking and Choosing Settings

The following parameters can be passed to the `slate` class:
```
slate::manage_kubernetes: true
slate::register_with_slate: true
slate::apply_security_policy: true
slate::manage_slate_admin_accounts: true
slate::enable_tuning: true
```

These can be changed to pick and choose what functionality you want from this module. If all are set to false, this module will only install packages and the SLATE CLI.

If `manage_kubernetes` is set to `false`, no `slate::kubernetes` parameters are required to be specified. Simiarly, if `register_with_slate` is set to `false`, no `slate::registration` parameters are required to be specified.

`apply_security_policy` must be set to `true` if `manage_kubernetes` is set to `true`. See REFERENCES.md for more details on each parameter.

## How Do I?
### Change podSubnet, serviceSubnet, etc
These are specified in the `slate::kubernetes::kubeadm_init::config` parameter. The default value for this parameter in `data/kubernetes.yaml` ensures the cluster is CIS compliant, so it is not recommended you completely override the default parameter. Rather, we recommend one of two options:
* Copy the default parameter in `data/slate.yaml` and replace values as needed.
* Use `deep_merge` behavior in Hiera (https://puppet.com/docs/puppet/5.5/configure_merge_behavior_hiera.html)

## Limitations

This module is not intended for running management of Kubernetes clusters. Only the following configurations are updated for running clusters:
* MetalLB config changes
* MetalLB upgrades
* Calico upgrades

All other configurations supplied in Hiera will _only_ be applied during cluster instantiation time (i.e. during `kubeadm init`).
