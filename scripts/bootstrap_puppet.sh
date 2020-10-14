#!/bin/bash
# This script will register a node with the CHPC Foreman/Puppet infrastructure.
# If the node's domain is not whitelisted by the Puppet Master, a
# `sudo /opt/puppetlabs/bin/puppetserver ca sign ...`
# is required to be run on the Puppet master.
set -eu


if [[ "$(uname)" != "Linux" ]]
then
    echo "Unsupported OS, must be run on Linux"
    exit 1
fi

if [[ ! -f /etc/os-release ]]
then
    echo "Unable to find /etc/os-release"
    exit 1
fi

set -a
. /etc/os-release
set +a

case "$ID" in
    centos)
        echo "Detected CentOS..."
        rpm -Uvh https://yum.puppet.com/puppet6-release-el-$VERSION_ID.noarch.rpm

        case "$VERSION_ID" in
            7)
                yum install puppet-agent -y ;;
            8)
                dnf install puppet-agent -y ;;
            *)
                echo "Unknown version of CentOS"
                exit 1
                ;;
        esac
        ;;

    ubuntu)
        echo "Detected Ubuntu..."

        TEMP_DEB="$(mktemp)"
        wget -O "$TEMP_DEB" https://apt.puppetlabs.com/puppet6-release-$UBUNTU_CODENAME.deb
        dpkg -i "$TEMP_DEB"
        rm -f "$TEMP_DEB"

        apt-get update
        apt-get install puppet-agent -y
        ;;

    *)
        echo "Unknown distribution"
        exit 1
        ;;
esac



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
