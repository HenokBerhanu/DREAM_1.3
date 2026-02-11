################################################################################################################################
# After finishing setting up k8s in the two nodes (Master node and cloud node) and insstaling CRI (containerd) inside the edge node, setting up kubeedge is the next step
################################################################################################################################

############################################################################################################################
# On the Edge node:  Install keadm (KubeEdge Installer) on the Edge Node
# version vv1.17.0
        # wget https://github.com/kubeedge/kubeedge/releases/download/v1.17.0/keadm-v1.17.0-linux-amd64.tar.gz
        # tar -zxvf keadm-v1.17.0-linux-amd64.tar.gz
        # sudo cp keadm-v1.17.0-linux-amd64/keadm/keadm /usr/local/bin/keadm
###################################################################################################

##########################################################################################################################
#Latest version as of January 2025
        # wget https://github.com/kubeedge/kubeedge/releases/download/v1.20.0/keadm-v1.20.0-linux-amd64.tar.gz
        # tar -zxvf keadm-v1.20.0-linux-amd64.tar.gz
        # sudo cp keadm-v1.20.0-linux-amd64/keadm/keadm /usr/local/bin/keadm
        # sudo chmod +x /usr/local/bin/keadm

#####################################################################
# best practive

wget https://github.com/kubeedge/kubeedge/releases/download/v1.22.1/keadm-v1.22.1-linux-amd64.tar.gz
tar -zxvf keadm-v1.22.1-linux-amd64.tar.gz
sudo cp keadm-v1.22.1-linux-amd64/keadm/keadm /usr/local/bin/keadm


sudo chmod +x /usr/local/bin/keadm

      # sudo rm -rf keadm-v1.20.0-linux-amd64 keadm-v1.20.0-linux-amd64.tar.gz
##############################################################

#############################################################################################################################

############################################################################################################################

#########################################################################################################################
# Verify the installation

keadm version
#########################################################################################################################

# From the cloudnode -- cloud core
sudo keadm gettoken --kube-config /etc/kubernetes/admin.conf

# consider the nodeport IP of the internal port 10000 why? 31427
sudo keadm join \
  --cloudcore-ipport=10.12.10.124:10000 \
  --token=17bad182c91474d94776646c25ace216d22987a13e0d3aeb54a05271b72c9240.eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NDg5MzQ2MjB9._FD8MMsZzdHr9FCFWR77RPsaGrsE1aRdNjElU38K_yw \
  --remote-runtime-endpoint=unix:///run/containerd/containerd.sock \
  --cgroupdriver=systemd \
  --kubeedge-version=1.22.1