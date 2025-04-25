# cd Security-Enforcement-Agent/
# docker build -t henok/security-enforcement-agent:v2 .
# docker tag henok/security-enforcement-agent:v2 henok28/security-enforcement-agent:v2
# docker push henok28/security-enforcement-agent:v2

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
kubectl apply -f security-agent-deployment.yaml -n edge-agents
kubectl rollout restart daemonset security-enforcement-agent -n edge-agents

kubectl get pods -n edge-agents -o wide
kubectl logs -n edge-agents <pod-name> -c enforcement-agent

# Confirm veth pair exists:
ip link show veth-sec

# Confirm OVS bridge has veth-br-sec:
sudo ovs-vsctl show


# Deploy kafka
# Kafka deployment was successful

# Lets fix issues with data plane agents

kubectl get pods -n edge-agents -o wide

kubectl logs -n edge-agents security-enforcement-agent-m6plc

kubectl describe pod -n edge-agents security-enforcement-agent-m6plc

# Check connectivity of kafka service from the edge node:
curl -s http://192.168.56.121:8181/onos/v1/flows/of:0000000000000001 --user onos:rocks
nc -zv kafka-service 9092


sudo tail -n 50 /var/log/pods/edge-agents_security-enforcement-agent-lvs2d_e75d1f72-a04c-4847-b356-cbe4aeb81340/enforcement-agent/23.log
2025-04-24T19:34:00.747351493Z stdout F [KAFKA] Broker not available, retrying in 5s... (1/10)
2025-04-24T19:34:07.755120046Z stdout F [KAFKA] Broker not available, retrying in 5s... (2/10)
2025-04-24T19:34:14.758554485Z stdout F [KAFKA] Broker not available, retrying in 5s... (3/10)
2025-04-24T19:34:21.76346197Z stdout F [KAFKA] Broker not available, retrying in 5s... (4/10)
2025-04-24T19:34:28.767156984Z stdout F [KAFKA] Broker not available, retrying in 5s... (5/10)
2025-04-24T19:34:35.771116257Z stdout F [KAFKA] Broker not available, retrying in 5s... (6/10)
