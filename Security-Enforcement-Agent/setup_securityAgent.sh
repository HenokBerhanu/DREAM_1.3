# cd Security-Enforcement-Agent/
# docker build -t henok/security-enforcement-agent:v1 .
# docker tag henok/security-enforcement-agent:v1 henok28/security-enforcement-agent:v1
# docker push henok28/security-enforcement-agent:v1

# setup veth Binding
# This makes veth-sec available in the hostNetwork namespace and veth-br-sec part of the br0 bridge.
sudo ip link add veth-sec type veth peer name veth-br-sec
sudo ip link set veth-br-sec up
sudo ip link set veth-sec up
sudo ovs-vsctl add-port br0 veth-br-sec

vagrant ssh-config MasterNode

# coppy from the host to the edge node
sudo scp -i /home/henok/DREAM_1.3/Kubernetes-deplyment/.vagrant/machines/MasterNode/virtualbox/private_key \
-P 2222 \
~/DREAM_1.3/Security-Enforcement-Agent/security-agent-deployment.yaml \
vagrant@127.0.0.1:/home/vagrant/

kubectl create namespace edge-agents

kubectl apply -f security-agent-deployment.yaml

kubectl get pods -n edge-agents -o wide

# Confirm veth pair exists:
ip link show veth-sec

# Confirm OVS bridge has veth-br-sec:
sudo ovs-vsctl show


# Deploy kafka










