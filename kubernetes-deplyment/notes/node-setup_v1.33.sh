#################################################
#https://kubernetes.io/ go to the documentation and search for "installing kubeadm"
#These instructions are for Kubernetes v1.33
#################################################

# Requirements for k8s version 1.33:
1. The kernel version should be 5.13 or later : uname -r (check from terminal)
2. kube-proxy requires nftables version 1.0.1 or later : nf --version (check from terminal)

#Install container runtime invironmnet (CRI)
###############################################
# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system
###############################################

####################################################
# Verify that net.ipv4.ip_forward is set to 1 with:
sysctl net.ipv4.ip_forward
####################################################

########################################################################
# Run the following command to uninstall all conflicting packages:
sudo apt remove $(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc | cut -f1)
#############################################################################

#############################################################################################################################
# Add Docker's official GPG key:
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update
####################################################################################################################################

##############################################
sudo apt install containerd.io
###############################################

####################################################################################
#sudo containerd config default > /etc/containerd/config.toml
sudo containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
############################################################################################

#####################################
sudo systemctl restart containerd
##########################################

#################################
systemctl status containerd
#################################

#######################################################################################################################################
#######################################################################################################################################
#######################################################################################################################################

# Regular worker node only
# If i am going to have a hybrid three node k8s cluster where one of the worker node is regular k8s worker node that directly joins the kube-api-server in- 
    # the master node and the second worker node is an edge node where KubeEdge is going to be setup. So i do not execute the below scripts on the edge node.

#########################################################################################################################################################
#########################################################################################################################################################
#########################################################################################################################################################

### Installing kubeadm, kubelet and kubectl
#####################################################################################
# Update the apt package index and install packages needed to use the Kubernetes apt repository:
sudo apt-get update
# apt-transport-https may be a dummy package; if so, you can skip that package
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
#####################################################################################

# Download the public signing key for the Kubernetes package repositories. The same signing key is used for all repositories so you can disregard the version 
    # in the URL:
##############################################################################################################################################
# If the directory `/etc/apt/keyrings` does not exist, it should be created before the curl command, read the note below.
# sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.33/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
##############################################################################################################################################

##############################################################################################################################################################################
# This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.33/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
##############################################################################################################################################################################

##################################################
# Update the apt package index, install kubelet, kubeadm and kubectl, and pin their version:
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
################################################

######################################################
# (Optional) Enable the kubelet service before running kubeadm:
sudo systemctl enable --now kubelet
################################################################

###################################################
# What's next?
# Click the "Using kubeadm to Create a Cluster" link at the bottom of the same page declare the master node and- 
    # the worker node (Accessing the these two files: /kubernetes-deplyment/notes/master.sh and /kubernetes-deplyment/notes/woreker.sh)
###################################################
