#!/bin/bash
#
# Set up /etc/hosts so we can resolve all the machines in the VirtualBox network
set -ex

IFNAME=$1  # Network interface passed as an argument
THISHOST=$2  # Hostname passed as an argument

# Get the primary IP for the specified interface
PRIMARY_IP=$(ip -4 addr show "$IFNAME" | grep "inet" | awk '{print $2}' | cut -d/ -f1)

# Extract network subnet (first three octets)
NETWORK=$(echo "$PRIMARY_IP" | awk -F. '{print $1"."$2"."$3}')

# Export PRIMARY IP as an environment variable
echo "PRIMARY_IP=${PRIMARY_IP}" | sudo tee -a /etc/environment > /dev/null
echo "ARCH=amd64" | sudo tee -a /etc/environment > /dev/null

# Remove outdated entries from /etc/hosts
sudo sed -i '/^.*ubuntu-jammy.*/d' /etc/hosts
sudo sed -i "/^.*${THISHOST}.*/d" /etc/hosts

# Update /etc/hosts with cluster node names
cat <<EOF | sudo tee -a /etc/hosts > /dev/null
${NETWORK}.102  MasterNode
${NETWORK}.121  CloudNode
${NETWORK}.122  EdgeNode
EOF
