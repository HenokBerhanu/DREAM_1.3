#################################################################################################################
sudo kubeadm init --apiserver-advertise-address=192.168.56.102 --pod-network-cidr=192.168.0.0/16 # 192.168.0.0/16 if Calico CNI is used # 10.244.0.0/16 if Flannel CNI is used
# or you can also provide image repo directory if there is a firewall issue or the aboove command got stuck taking longer time
sudo kubeadm init --apiserver-advertise-address=192.168.56.102 --pod-network-cidr=192.168.0.0/16 --image-repository registry.k8s.io
#################################################################################################################

#########################################################################
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
##################################################################

#########################################################################################3
sudo stat -c %a /etc/kubernetes/admin.conf
sudo chmod 644 /etc/kubernetes/admin.conf
###############################################################################

########################################################################################
sudo -i
swapoff -a
exit
###########################################################################################

#####################################################################################################
# Install Flannel CNI, the pod network cidr shall be 10.244.0.0/16
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
#####################################################################################################

#####################################################################################################################################
# install Calico pod network addon the pod network cidr shall be 192.168.0.0/16
kubectl --kubeconfig=/etc/kubernetes/admin.conf create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/tigera-operator.yaml 
#####################################################################################################################################
##############################################################################################################################################
kubectl --kubeconfig=/etc/kubernetes/admin.conf create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/custom-resources.yaml
#####################################################################################################################################



#################################                                                                        ############################
#################################Below are the diagnosis commands that i use when the kubectl shows error############################
#################################                                                                        ############################

sudo systemctl restart kubelet
sudo systemctl restart kubelet.service
sudo systemctl status kubelet
sudo systemctl status kubelet.service


##################################################
# kubelet requires swap off
sudo -i
swapoff -a
exit
##############################################

##########################################################
# keep swap off after reboot
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
###################################################


###############################################################
export KUBECONFIG=/etc/kubernetes/admin.conf
##################################################################

##################################################################
sudo stat -c %a /etc/kubernetes/admin.conf
##################################################################

################################################
sudo chmod 644 /etc/kubernetes/admin.conf
################################################

#######################How do you know if your k8s cluster has Roll-Based Access Control (RBAC)?#############################
kubectl api-versions ## or 
kubectl api-versions | grep rbac.authorization.k8s.io/v1
###########################################################################################################


###########################################################################################################
#Install Multus cni with flannel:
      https://github.com/k8snetworkplumbingwg/multus-cni
#Visit this site for NAD 
     https://ubuntu.com/kubernetes/docs/cni-multus
#################################################################################################################

#############################################################################################################
#Install helm chart in the cluster: 
             #Check if installed:
             helm version
             helm list --all-namespaces
             #Then install from the package manager (ubuntu): 
             https://helm.sh/docs/intro/using_helm/
#Or better to use snap for ubuntu jammy:      
            sudo snap install helm --classic
###########################################################################################################

# I am creating a single node cluster, make sure to taint the control plane restriction to schedule pods in it (This is only for microk8s)
kubectl taint node --all node-role.kubernetes.io/control-plane:NoSchedule-
