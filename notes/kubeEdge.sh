################################################################################################################################
# After finishing setting up k8s in the two nodes (Master node and cloud node) and insstaling CRI (containerd) inside the edge node, setting up kubeedge is the next step
################################################################################################################################

############################################################################################################################
# On the Edge node:  Install keadm (KubeEdge Installer) on the Edge Node

wget https://github.com/kubeedge/kubeedge/releases/download/v1.17.0/keadm-v1.17.0-linux-amd64.tar.gz
tar -zxvf keadm-v1.17.0-linux-amd64.tar.gz
sudo cp keadm-v1.17.0-linux-amd64/keadm/keadm /usr/local/bin/keadm

############################################################################################################################

#########################################################################################################################
# Verify the installation

keadm version
#########################################################################################################################

######################################################################################################################
# On the master node: Set Up CloudCore on the Master Node

# Install keadm on the master node
wget https://github.com/kubeedge/kubeedge/releases/download/v1.17.0/keadm-v1.17.0-linux-amd64.tar.gz
tar -zxvf keadm-v1.17.0-linux-amd64.tar.gz
sudo cp keadm-v1.17.0-linux-amd64/keadm/keadm /usr/local/bin/keadm

########################################################################################################################

#########################################################################################################################
# Initialize CloudCore on the Master Node

#keadm init --advertise-address="THE-EXPOSED-IP" --kubeedge-version=v1.17.0 --kube-config=/root/.kube/config
sudo keadm init --advertise-address=192.168.56.102 --kubeedge-version=v1.17.0 --kube-config=$HOME/.kube/config

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


# Check kubeedge namespace is created
kubectl get all -n kubeedge
##########################################################################################################################

############################################################################################################################
# Get the Edge Node Token

sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config

keadm gettoken
############################################################################################################################


###############################################################################################################################
# On the Edge node: Join the Edge Node to KubeEdge

#keadm join --cloudcore-ipport="THE-EXPOSED-IP":10000 --token=27a37ef16159f7d3be8fae95d588b79b3adaaf92727b72659eb89758c66ffda2.eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE1OTAyMTYwNzd9.JBj8LLYWXwbbvHKffJBpPd5CyxqapRQYDIXtFZErgYE --kubeedge-version=v1.12.1
sudo keadm join --cloudcore-ipport=192.168.56.102:10000 --token=392d1a57dec8a503b6bfe1886ce9aafdd3a43650540fef26de1890ffaf0edaf4.eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NDIxNjA2MzV9.aSITt8hCtYVusJ5eeMNSqHEtShuz826D0QGO-Qnx6TU --kubeedge-version=v1.17.0

# Verify the edge mode connection on the master node
kubectl get nodes
################################################################################################################################

# Deplooy workloads to the edge node

# edge-nginx.yaml

                apiVersion: v1
                kind: Pod
                metadata:
                name: edge-nginx
                spec:
                containers:
                - name: nginx
                image: nginx
                nodeSelector:
                "node-role.kubernetes.io/edge": "true"
# apply it
kubectl apply -f edge-nginx.yaml
###################################################################################################################################

######################################################################################
# Monitor Edge-to-Cloud Communication

# Check EdgeCore logs (on the Edge Node)

journalctl -u edgecore -f

# Check CloudCore logs (on the Master Node)

journalctl -u cloudcore -f

# Verify the Pod is Running on the Edge Node

kubectl get pods -o wide
##########################################################################################



