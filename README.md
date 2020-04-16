# slate-puppet

A Puppet module that configures a Kubernetes cluster to be SLATE-ready.

THIS README IS OUT OF DATE AS OF 2020/04/15.

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with slate-puppet](#setup)
    * [What slate-puppet affects](#what-slate-puppet-affects)
    * [Setup requirements](#setup-requirements)
3. [Usage - Configuration options and additional functionality](#usage)

## Description

This Puppet module, by default, will install a single-node Kubernetes cluster and register it with SLATE.

It is designed to be highly modular, thus you can choose not to have this module configure a single-node
Kubernetes cluster and instead use something like puppetlabs-kubernetes to bring up your Kubernetes cluster.
The rest of the module can then be used to register that cluster with SLATE.

## Setup

### What slate-puppet affects

* `accounts` will create and manage SLATE administrator accounts.
* `packages` will install and manage SLATE packages, including the SLATE CLI.
* `registration` will register your Kubernetes cluster with SLATE.
* `security` will manage firewall rules, SSH rules, and selinux settings.
* `tuning` will manage sysctl settings.
* `kubeadm::` will install and configure your box to be a single-node Kubernetes cluster.
* `dell::` installs Dell utilities.

### Setup Requirements

If `single_node_cluster` is set to false, then a Kubernetes installation must be present before running
this module. Please see the documentation of `registration` for more details.

For automatic SLATE cluster registeration, all SLATE API related parameters must be set.

## Usage

For a single-node installation, add `include slate` to the node's definition.

For a cluster using some other Kubernetes management, add
```
class { 'slate':
    single_node_cluster => false,
}
```

## Limitations

Several of the modules are still a WIP, such as security.
