#!/bin/sh
kubeadm reset -f
systemctl stop kubelet

if [ -d '/etc/kubernetes' ]; then
    rm -rf /etc/kubernetes/*
fi

if [ -d '/var/lib/kubelet' ]; then
    rm -rf /var/lib/kubelet
fi

if [ -d '/var/lib/etcd' ]; then
    rm -rf /var/lib/etcd
fi
iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X
