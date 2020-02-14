# slate-puppet

A Puppet module that auto configures a single-node SLATE cluster.

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with slate-puppet](#setup)
    * [What slate-puppet affects](#what-slate-puppet-affects)
    * [Setup requirements](#setup-requirements)
3. [Usage - Configuration options and additional functionality](#usage)

## Description

This Puppet module will install and setup SLATE packages, Kubernetes, accounts, and more automatically.

If certain Hiera parameters such as the SLATE CLI token are present, this module will auto register your cluster with the SLATE API server.

## Setup

### What slate-puppet affects

This module will do the following:
 * Setup new user accounts
 * Install and configure Kubernetes (including CNI and MetalLB)
 * Disable firewalld for Kubernetes
 * Perform sysctl tuning for Kubernetes

### Setup Requirements

For MetalLB configurations, the Hiera parameters for MetalLB must be set.

For automatic SLATE cluster registeration, all SLATE API related parameters must be set.

## Usage

`include slate` for a specific node to register it.

## Limitations

This module only supports single-node SLATE clusters configurations. Multi-node support is still TBD.
