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

# In the cloud node:
#####################################################################
# best practive
  # wget https://github.com/kubeedge/kubeedge/releases/download/v1.20.0/keadm-v1.20.0-linux-amd64.tar.gz
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

######################################################################################################################
# On the master node: Set Up CloudCore on the Master Node

# Install keadm on the master node
##########################################################################################################################
#Latest version as of January 2025
        # wget https://github.com/kubeedge/kubeedge/releases/download/v1.20.0/keadm-v1.20.0-linux-amd64.tar.gz
        # tar -zxvf keadm-v1.20.0-linux-amd64.tar.gz
        # sudo cp keadm-v1.20.0-linux-amd64/keadm/keadm /usr/local/bin/keadm
        # sudo chmod +x /usr/local/bin/keadm
#############################################################################################################################

########################################################################################################################

#########################################################################################################################
# Initialize CloudCore on the Master Node

#keadm init --advertise-address="THE-EXPOSED-IP" --kubeedge-version=v1.17.0 --kube-config=/root/.kube/config
# Not the latest version
          # sudo keadm init --advertise-address=192.168.56.102 --kubeedge-version=v1.17.0 --kube-config=/etc/kubernetes/admin.conf
#keadm init --advertise-address=192.168.56.102 --kube-config=/etc/kubernetes/admin.conf

          # sudo keadm init --advertise-address=192.168.56.102 --kubeedge-version=1.20.0 --kube-config=/etc/kubernetes/admin.conf

# it should be the cloudnodes IP to be used as an advertise address
sudo keadm init \
  --advertise-address=10.12.10.124 \
  --kube-config=/etc/kubernetes/admin.conf

# For multiple edge nodes. EdgeMesh is useful when you have multiple Edge Nodes because it enables direct edge-to-edge communication without needing to route traffic through the cloud (Master node)
# keadm init --set server.advertiseAddress="THE-EXPOSED-IP" --set server.nodeName=allinone  --kube-config=/root/.kube/config --force --external-helm-root=/root/go/src/github.com/edgemesh/build/helm --profile=edgemesh

# the THE-EXPOSED-IP is the IP of the master node

# the out put should be:

        # Kubernetes version verification passed, KubeEdge installation will start...
        # CLOUDCORE started
        # =========CHART DETAILS=======
        # Name: cloudcore
        # LAST DEPLOYED: Sat Mar 15 00:42:58 2025
        # NAMESPACE: kubeedge
        # STATUS: deployed
        # REVISION: 1

# Check you should see this
kubectl -n kubeedge get pods,svc,cm
NAME                               READY   STATUS    RESTARTS   AGE
pod/cloud-iptables-manager-jqdd5   1/1     Running   0          3m42s
pod/cloudcore-58b79bbcdf-zzlc4     1/1     Running   0          3m42s

NAME                TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                                             AGE
service/cloudcore   ClusterIP   10.103.189.106   <none>        10000/TCP,10001/UDP,10002/TCP,10003/TCP,10004/TCP   3m42s

NAME                         DATA   AGE
configmap/cloudcore          1      3m42s
configmap/kube-root-ca.crt   1      3m42s
configmap/tunnelport         0      3m41s

##########################################################################
# keadm manifest generate
# keadm manifest generate --advertise-address="THE-EXPOSED-IP" --kube-config=/root/.kube/config > kubeedge-cloudcore.yaml

#keadm manifest generate --advertise-address=192.168.56.102 --kube-config=/etc/kubernetes/admin.conf > kubeedge-cloudcore.yaml

# keadm deprecated init
# keadm deprecated init --advertise-address="THE-EXPOSED-IP"

#keadm deprecated init --advertise-address=192.168.56.102

##############################################################################

which cloudcore
sudo ls -l /usr/local/bin/cloudcore