#!/bin/bash
# This script will register a node with the CHPC Foreman/Puppet infrastructure.
# If the node's domain is not whitelisted by the Puppet Master, a
# `sudo /opt/puppetlabs/bin/puppetserver ca sign ...`
# is required to be run on the Puppet master.

rpm -Uvh https://yum.puppet.com/puppet6-release-el-7.noarch.rpm

yum install puppet-agent -y

cat <<EOF > /etc/puppetlabs/puppet/puppet.conf
[main]
vardir = /opt/puppetlabs/puppet/cache
logdir = /var/log/puppetlabs/puppet
rundir = /var/run/puppetlabs
ssldir = /etc/puppetlabs/puppet/ssl

[agent]
pluginsync      = true
report          = true
ignoreschedules = true
ca_server       = foreman.chpc.utah.edu
certname        = $(hostname)
server          = foreman.chpc.utah.edu
EOF

/opt/puppetlabs/bin/puppet resource service puppet ensure=running enable=true
