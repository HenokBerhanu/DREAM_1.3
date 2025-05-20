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
curl -LO https://github.com/kubeedge/kubeedge/releases/download/v1.20.0/keadm-v1.20.0-linux-amd64.tar.gz
tar -zxvf keadm-v1.20.0-linux-amd64.tar.gz
sudo mv keadm-v1.20.0-linux-amd64/keadm/keadm /usr/local/bin/keadm
sudo chmod +x /usr/local/bin/keadm

sudo rm -rf keadm-v1.20.0-linux-amd64 keadm-v1.20.0-linux-amd64.tar.gz
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

sudo keadm init \
  --advertise-address=192.168.56.102 \
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


# install cloud core manually if it is not installed with init
wget https://github.com/kubeedge/kubeedge/releases/download/v1.20.0/kubeedge-v1.20.0-linux-amd64.tar.gz
tar -zxvf kubeedge-v1.20.0-linux-amd64.tar.gz

sudo cp kubeedge-v1.20.0-linux-amd64/cloud/cloudcore/cloudcore /usr/local/bin/cloudcore
sudo chmod +x /usr/local/bin/cloudcore

##########################
tar zxvf kubeedge-v1.20.0-linux-amd64.tar.gz
cd kubeedge-v1.20.0-linux-amd64
sudo cp ~/kubeedge-v1.20.0-linux-amd64/cloud/cloudcore/cloudcore /usr/local/bin/
sudo chmod +x /usr/local/bin/cloudcore
#############################

#################################################################################################################

# Ensure CloudCore Has Access to KubeConfig
sudo mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
export KUBECONFIG=$HOME/.kube/config

export KUBECONFIG=/etc/kubernetes/admin.conf


# verify kubeconfig path
ls -l /etc/kubernetes/admin.conf
ls -l $HOME/.kube/config


ls -l /etc/kubeedge/config/cloudcore.yaml

# sudo mkdir -p /etc/kubeedge/config
# sudo cloudcore --defaultconfig > /etc/kubeedge/config/cloudcore.yaml
# sudo cloudcore --kubeconfig=/etc/kubernetes/admin.conf
# sudo cloudcore --kubeconfig=/etc/kubernetes/admin.conf

sudo mkdir -p /etc/kubeedge/config
sudo cloudcore --defaultconfig | sudo tee /etc/kubeedge/config/cloudcore.yaml > /dev/null

# Look for the kubeAPIConfig section and ensure it contains the correct path:
sudo nano /etc/kubeedge/config/cloudcore.yaml


# Look for the kubeAPIConfig section and ensure it contains the correct path:
kubeAPIConfig:
  kubeConfig: "/etc/kubernetes/admin.conf"

# Ensure advertiseAddress is set correctly to 192.168.56.102
# Ctrl+X, then Y, then Enter

#start CloudCore:
sudo cloudcore --config=/etc/kubeedge/config/cloudcore.yaml
sudo cloudcore --config=/etc/kubeedge/config/cloudcore.yaml

#######################################################################################
# Register CloudCore as a Systemd Service
sudo nano /etc/systemd/system/cloudcore.service
# paste this
[Unit]
Description=KubeEdge CloudCore
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/cloudcore --config=/etc/kubeedge/config/cloudcore.yaml
Restart=always
User=root

[Install]
WantedBy=multi-user.target

# then
sudo systemctl daemon-reload
sudo systemctl enable cloudcore
sudo systemctl start cloudcore
sudo systemctl status cloudcore

# Verify CloudCore is Listening on Port 10002
sudo netstat -tulnp | grep 10002
# if not listening, check logs
sudo journalctl -u cloudcore -xe


#####################################################################################

sudo systemctl daemon-reload
sudo systemctl enable cloudcore
sudo systemctl restart cloudcore
sudo systemctl status cloudcore

sudo systemctl daemon-reload
sudo systemctl restart cloudcore
sudo systemctl status cloudcore

# sudo /usr/local/bin/cloudcore --config=/etc/kubeedge/config/cloudcore.yaml
# # manually generate a default config:
# sudo cloudcore --defaultconfig > /etc/kubeedge/config/cloudcore.yaml
# sudo cloudcore --defaultconfig | sudo tee /etc/kubeedge/config/cloudcore.yaml > /dev/null
# sudo cloudcore --defaultconfig | sudo tee /etc/kubeedge/config/cloudcore.yaml > /dev/null



################################################################################################################

# Check kubeedge namespace is created
kubectl get all -n kubeedge
##########################################################################################################################

############################################################################################################################
# Get the Edge Node Token
keadm gettoken
# or
sudo keadm gettoken --kube-config /etc/kubernetes/admin.conf

############################################################################################################################


###############################################################################################################################
# On the Edge node: Join the Edge Node to KubeEdge

#keadm join --cloudcore-ipport="THE-EXPOSED-IP":10000 --token=27a37ef16159f7d3be8fae95d588b79b3adaaf92727b72659eb89758c66ffda2.eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE1OTAyMTYwNzd9.JBj8LLYWXwbbvHKffJBpPd5CyxqapRQYDIXtFZErgYE --kubeedge-version=v1.12.1
# is not updated
# sudo keadm join --cloudcore-ipport=192.168.56.102:10000 --token=d9283db963e8b5211dd0fdd280a0e1de8cea5617bc6a944648c830ba218bd1a1.eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NDI0MjU3ODh9.fcI-tp9zW3-QDWMMJ1TFc2k6V69eNIPhuVQRvDhLmu0 --kubeedge-version=v1.17.0
# sudo keadm join --cloudcore-ipport=192.168.56.102:10000 --token=d9283db963e8b5211dd0fdd280a0e1de8cea5617bc6a944648c830ba218bd1a1.eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NDI0MjU3ODh9.fcI-tp9zW3-QDWMMJ1TFc2k6V69eNIPhuVQRvDhLmu0 --kubeedge-version=v1.17.0 --kube-config=/etc/kubernetes/admin.conf --cgroupdriver=systemd

vagrant ssh-config MasterNode

# coppy from the host to the edge node
sudo scp -i /home/henok/DREAM_1.3/Kubernetes-deplyment/.vagrant/machines/MasterNode/virtualbox/private_key \
-P 2222 \
~/DREAM_1.3/Kubernetes-deplyment/notes/cloudcore-svc-nodeport.yaml \
vagrant@127.0.0.1:/home/vagrant/

kubectl -n kubeedge apply -f cloudcore-svc-nodeport.yaml

########################################################################################################################
# Updated one. Use one them
sudo keadm join --cloudcore-ipport=192.168.56.102:10000 \
  --token=59ed3a0b63a9a5447a8b3aed9838ae0893302ab3d623ac5a123589679e08c9bd.eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NDI0OTY3ODd9.0GDq-L1CUmq2CLXyE3zZnarSlqH7MTrVQzNAmRPpL3A \
  --kubeedge-version=v1.17.0 \
  --remote-runtime-endpoint=unix:///run/containerd/containerd.sock \
  --cgroupdriver=systemd


sudo keadm join --cloudcore-ipport=192.168.56.102:10000 \
        --token=51656d166ae09290d62bfd7f4cbe94f5ba2bd375ddcc32ebe18893ae54e2d968.eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NDc1MTMyNDJ9.OKnsrKI7LIrlEHBseqcQOKsyE-sdmQFltN_E_gOaLbw \
        --kubeedge-version=1.20.0 \
        --kube-config=/etc/kubernetes/admin.conf \
        --remote-runtime-endpoint=unix:///run/containerd/containerd.sock \
        --cgroupdriver=systemd

sudo keadm join \
  --cloudcore-ipport=192.168.56.121:30002 \
  --token=51656d166ae09290d62bfd7f4cbe94f5ba2bd375ddcc32ebe18893ae54e2d968.eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NDc1MTMyNDJ9.OKnsrKI7LIrlEHBseqcQOKsyE-sdmQFltN_E_gOaLbw \
  --remote-runtime-endpoint=unix:///run/containerd/containerd.sock \
  --kubeedge-version=1.20.0 \
  --cgroupdriver=systemd

##################################################################################################################

##############################################################################################
# Verify EdgeCore is Running

sudo systemctl status edgecore

# at this point there might be error with the CNI, so Check Installed CNI Plugins:
ls -l /opt/cni/bin/
# Expected Output: You should see binaries for CNI plugins like bridge, host-local, loopback, etc.

# Check if the CNI configuration files exist:
ls -l /etc/cni/net.d/


# If empty or missing, install CNI plugins:
sudo apt-get update
sudo apt-get install -y containernetworking-plugins

# then
sudo systemctl restart edgecore
sudo systemctl status edgecore

sudo vim /etc/kubeedge/config/edgecore.yaml


#If the issue persists, try:
journalctl -u edgecore -xe

#verify CloudCore Port Connectivity
curl -v https://192.168.56.102:10000



######################################################################

##########################################################
# Check if EdgeNode is Connected

kubectl get nodes

# If edgenode is NotReady, check on the edge node:
sudo journalctl -u edgecore -f --no-pager
########################################################

############################################################################
# Install CNI on EdgeNode (If Needed)
# sudo mkdir -p /etc/cni/net.d/
# scp <MasterNode_IP>:/etc/cni/net.d/10-calico.conflist /etc/cni/net.d/
# scp <MasterNode_IP>:/etc/cni/net.d/calico-kubeconfig /etc/cni/net.d/
# sudo systemctl restart edgecore

# on the master node
sudo scp /etc/cni/net.d/10-calico.conflist vagrant@192.168.56.122:/home/vagrant/
sudo scp /etc/cni/net.d/calico-kubeconfig vagrant@192.168.56.122:/home/vagrant/

# on the edge node
sudo mkdir -p /etc/cni/net.d/
sudo mv /home/vagrant/10-calico.conflist /etc/cni/net.d/
sudo mv /home/vagrant/calico-kubeconfig /etc/cni/net.d/
####################################################################################

sudo scp /opt/cni/bin/calico vagrant@192.168.56.122:/home/vagrant/
sudo scp /opt/cni/bin/calico-ipam vagrant@192.168.56.122:/home/vagrant/

sudo mv /home/vagrant/calico /opt/cni/bin/
sudo mv /home/vagrant/calico-ipam /opt/cni/bin/

sudo systemctl restart edgecore
sudo systemctl status edgecore

sudo systemctl restart containerd
sudo systemctl status containerd
#####################################################################################################
# Do this to exclude main cni to function on the edge node
kubectl label node edgenode edge.kubeedge.io/exclude-cni=true

# then add under spec.template.spec:
kubectl edit daemonset kube-flannel-ds -n kube-flannel

# Add this:
- key: edge.kubeedge.io/exclude-cni
  operator: NotIn
  values:
  - "true"
###############################################################################################
# Two pods from calico-system ns fails at the edge node so check it
kubectl get pods -A -o wide
kubectl logs -n calico-system calico-node-dnzw5

# most of the time the failure is: dial tcp 192.168.56.122:10350: connect: connection refused, which is the ip of the edge node
# it means that the tunnel between CloudCore and EdgeCore is not working.

# on the edge node: Confirm that EdgeCore is attempting to connect to CloudCore:
sudo netstat -tulnp | grep 10350

# On the EdgeNode, try to reach CloudCore:
curl -v https://192.168.56.102:10350

# On the MasterNode, try to reach EdgeCore:
curl -v https://192.168.56.122:10350

sudo rm -rf /etc/kubeedge

sudo rm -rf /etc/kubeedge/
sudo rm -rf /var/lib/kubeedge/


ls -la /etc/kubeedge
                # answer: ls: cannot access '/etc/kubeedge': No such file or directory

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

sudo journalctl -u edgecore -f

# Check CloudCore logs (on the Master Node)

journalctl -u cloudcore -f

# Verify the Pod is Running on the Edge Node

kubectl get pods -o wide
##########################################################################################

modules:
 18   cloudHub:
 19     advertiseAddress:
 20     - 10.0.2.15

# kubectl get installation default -n tigera-operator -o yaml

# kubectl edit installation default -n tigera-operator

# kubectl rollout restart deploy tigera-operator -n tigera-operator

echo NWI5NjE2NzE1ODJjZmE0Y2RmMjk1M2EzZjY4NDg1NjAyNDAyMmExNGQxZWQ0NDYxMTE0MmRiYWE3NDNjMTIzYy5leUpoYkdjaU9pSklVekkxTmlJc0luUjVjQ0k2SWtwWFZDSjkuZXlKbGVIQWlPakUzTkRNeU9UWTBPRFo5Lk5QMWpuM2xDbk5DRUVYME5BaHFQYk05UFhfVHBkcG9EOE5iZmozUTVEajQ= |base64 -d


sudo keadm reset edge

# copy ca and certs folder from the edge node to the host to coppy it to the master directory
vagrant ssh-config EdgeNode

# then
mkdir -p ~/edge-kubeedge-backup
ssh -i /home/henok/DREAM_1.3/Kubernetes-deplyment/.vagrant/machines/EdgeNode/virtualbox/private_key \
    -p 2201 vagrant@127.0.0.1 \
  "sudo tar czf - -C /etc/kubeedge ca certs" \
| tar xzf - -C ~/edge-kubeedge-backup

# then coppy it to the master node cloud core tls directory
vagrant ssh-config MasterNode

# coppy from the host to the edge node
sudo scp -i /home/henok/DREAM_1.3/Kubernetes-deplyment/.vagrant/machines/MasterNode/virtualbox/private_key \
-P 2222 \
~/edge-kubeedge-backup/ca/rootCA.crt \
~/edge-kubeedge-backup/certs/server.crt \
~/edge-kubeedge-backup/certs/server.key \
vagrant@127.0.0.1:/home/vagrant/

# then on the master node, move those files to the required directory
#sudo mkdir -p /etc/kubeedge/ca/
#sudo mkdir -p /etc/kubeedge/certs/
sudo mv rootCA.crt /etc/kubeedge/ca/
sudo mv server.crt /etc/kubeedge/certs/
sudo mv server.key /etc/kubeedge/certs/



#########################################
#####################################################
##################################################################
########################################################################
# if you ever ran keadm before:
sudo keadm reset cloud    || true
sudo keadm reset edge     || true

# stop/remove any hand-rolled cloudcore/edgecore services
sudo systemctl stop cloudcore   2>/dev/null || true
sudo systemctl disable cloudcore 2>/dev/null|| true
sudo rm /etc/systemd/system/cloudcore.service 2>/dev/null

sudo systemctl stop edgecore    2>/dev/null || true
sudo systemctl disable edgecore  2>/dev/null|| true
sudo rm /etc/systemd/system/edgecore.service  2>/dev/null

# delete any leftover KubeEdge directory
sudo rm -rf /etc/kubeedge

# Install keadm On both cloud and edge:
curl -LO https://github.com/kubeedge/kubeedge/releases/download/v1.20.0/keadm-v1.20.0-linux-amd64.tar.gz
tar -zxvf keadm-v1.20.0-linux-amd64.tar.gz
sudo mv keadm-v1.20.0-linux-amd64/keadm/keadm /usr/local/bin/keadm
sudo chmod +x /usr/local/bin/keadm

# Check version
keadm version

sudo keadm init --advertise-address=192.168.56.121 --kubeedge-version=1.20.0 --kube-config=/etc/kubernetes/admin.conf

kubectl -n kubeedge get pods,svc,cm

kubectl -n kubeedge apply -f cloudcore-svc-nodeport.yaml

sudo keadm gettoken --kube-config /etc/kubernetes/admin.conf

sudo keadm join \
  --cloudcore-ipport=192.168.56.121:30002 \
  --token=65d641eb23b1738f12d09cfe1055301ee24cceb0eef7e8af84a0593b9ae5b77d.eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NDc3NjA5ODZ9.EAh1JkEYIZrTwKSogaRvsUq9QSr42whpFEkTqSy0tzs \
  --kubeedge-version=1.20.0 \
  --remote-runtime-endpoint=unix:///run/containerd/containerd.sock \
  --cgroupdriver=systemd

sudo systemctl daemon-reexec
sudo systemctl restart edgecore
sudo journalctl -u edgecore -f


sudo ls -l /etc/kubeedge/ca/rootCA.crt
sudo ls -l /etc/kubeedge/certs/server.crt
sudo ls -l /etc/kubeedge/certs/server.key


# install cloud core manually if it is not installed with init
wget https://github.com/kubeedge/kubeedge/releases/download/v1.20.0/kubeedge-v1.20.0-linux-amd64.tar.gz
tar -zxvf kubeedge-v1.20.0-linux-amd64.tar.gz
sudo cp kubeedge-v1.20.0-linux-amd64/cloud/cloudcore/cloudcore /usr/local/bin/cloudcore
sudo chmod +x /usr/local/bin/cloudcore

wget https://github.com/kubeedge/kubeedge/releases/download/v1.20.0/kubeedge-v1.20.0-linux-amd64.tar.gz
tar -xvzf kubeedge-v1.20.0-linux-amd64.tar.gz
sudo cp kubeedge-v1.20.0-linux-amd64/cloud/cloudcore /usr/local/bin/
