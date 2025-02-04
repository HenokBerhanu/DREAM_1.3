# -*- mode: ruby -*-
# vi:set ft=ruby sw=2 ts=2 sts=2:

# Define the number of master and worker nodes
# If this number is changed, remember to update setup-hosts.sh script with the new hosts IP details in /etc/hosts of each VM.
NUM_WORKER_NODE = 2

IP_NW = "192.168.56."
MASTER_IP_START = 102
NODE_IP_START = 120

# Sets up hosts file and DNS
def setup_dns(node)
  # Set up /etc/hosts
  node.vm.provision "setup-hosts", :type => "shell", :path => "ubuntu/vagrant/setup-hosts.sh" do |s|
    s.args = ["enp0s8", node.vm.hostname]
  end
  # Set up DNS resolution
  node.vm.provision "setup-dns", type: "shell", :path => "ubuntu/update-dns.sh"
end

# Runs provisioning steps that are required by masters and workers
def provision_kubernetes_node(node)
  # Set up kernel parameters, modules and tunables
  node.vm.provision "setup-kernel", :type => "shell", :path => "ubuntu/setup-kernel.sh"
  # Set up ssh
  node.vm.provision "setup-ssh", :type => "shell", :path => "ubuntu/ssh.sh"
  # Set up DNS
  setup_dns node
  # Install cert verification script
  node.vm.provision "shell", inline: "ln -s /ubuntu/cert_verify.sh /home/vagrant/cert_verify.sh"
end

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://vagrantcloud.com/search.
  # config.vm.box = "base"
  config.vm.box = "ubuntu/jammy64"
  config.vm.boot_timeout = 900

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  config.vm.box_check_update = false

  # Provision Master Nodes
  config.vm.define "MasterNode" do |node|
    # Name shown in the GUI
    node.vm.provider "virtualbox" do |vb|
      vb.name = "MasterNode"
      vb.memory = 4096 #8192
      vb.cpus = 4 #3
    end
    node.vm.hostname = "MasterNode"
    node.vm.network :private_network, ip: IP_NW + "#{MASTER_IP_START}"
    node.vm.network "forwarded_port", guest: 22, host: "#{2710}"
    provision_kubernetes_node node
    # Install (opinionated) configs for vim and tmux on master-node.
    node.vm.provision "file", source: "./ubuntu/tmux.conf", destination: "$HOME/.tmux.conf"
    node.vm.provision "file", source: "./ubuntu/vimrc", destination: "$HOME/.vimrc"
    node.vm.provision "file", source: "./tools/approve-csr.sh", destination: "$HOME/approve-csr.sh"
  end

  # Provision Worker Nodes with custom names
  WORKER_NODE_NAMES = ["CloudNode", "EdgeNode"] # Replace with your desired names

  WORKER_NODE_NAMES.each_with_index do |name, index|
    config.vm.define name do |node|
      node.vm.provider "virtualbox" do |vb|
        vb.name = name
        vb.memory = 8192 # 32768 1024 16384
        vb.cpus = 6 #4
      end
      node.vm.hostname = name
      node.vm.network :private_network, ip: IP_NW + "#{NODE_IP_START + index + 1}"
      node.vm.network "forwarded_port", guest: 22, host: "#{2720 + index + 1}"
      provision_kubernetes_node node
    end
  end
end