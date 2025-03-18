#################################################
#https://kubernetes.io/ go to the documentation and search for "install kubeadm"
#These instructions are for Kubernetes v1.28.
#################################################
#Install container runtime invironmnet (CRI)
###############################################
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system
###############################################

####################################################
lsmod | grep br_netfilter
lsmod | grep overlay
##############################################

###############################################################################################
sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward
##############################################################################################

#############################################################################################################################
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
####################################################################################################################################

##############################################
sudo apt-get install containerd.io
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

###############################################################################################
#######################################################################################################################################
####################################################################################################
# Regular worker node only
# If i am going to have a hybrid three node k8s cluster where one of the worker node is regular k8s worker node that directly joins the kube-api-server in 
#the master node and the second worker node is an edge node where KubeEdge is going to be setup. So i do not execute the below scripts on the edge node.

#########################################################################################################################################################3
#############################################################################################################################################
#####################################################################################################

#####################################################################################
sudo apt-get update
# apt-transport-https may be a dummy package; if so, you can skip that package
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
#####################################################################################

##############################################################################################################################################
# If the folder `/etc/apt/keyrings` does not exist, it should be created before the curl command, read the note below.
# sudo mkdir -p -m 755 /etc/apt/keyrings
sudo curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
##############################################################################################################################################

##############################################################################################################################################################################
# This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list
# This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list
sudo echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
##############################################################################################################################################################################

##################################################
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
################################################