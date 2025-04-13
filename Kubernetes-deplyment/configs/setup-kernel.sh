#!/bin/bash
#
# Sets up the kernel with the requirements for running Kubernetes
set -ex

# Add br_netfilter kernel module safely
cat <<EOF | tee /etc/modules
ip_vs
ip_vs_rr
ip_vs_wrr
ip_vs_sh
br_netfilter
nf_conntrack
EOF

# Load modules immediately to avoid reboot issues
modprobe ip_vs
modprobe ip_vs_rr
modprobe ip_vs_wrr
modprobe ip_vs_sh
modprobe br_netfilter
modprobe nf_conntrack
systemctl restart systemd-modules-load.service

# Set network tunables (sysctl settings)
cat <<EOF | tee /etc/sysctl.d/10-kubernetes.conf
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-arptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

# Apply the settings only if the file exists
if [ -f /etc/sysctl.d/10-kubernetes.conf ]; then
    sysctl --system
else
    echo "Error: sysctl file not found!"
fi