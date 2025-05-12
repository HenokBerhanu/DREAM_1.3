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




##################################################################
The two agents was failing frequently and i solved using this pprocedure
###############################################################
sudo crictl ps -a | grep security-enforcement-agent
2dbcb21286734       33f2cb1f3975d       2 minutes ago            Exited              enforcement-agent        5                   d0a3162666fc5       security-enforcement-agent-7jv2z
c1a5fc8d67dae       ff7a7936e9306       11 minutes ago           Exited              veth-setup               0                   d0a3162666fc5       security-enforcement-agent-7jv2z
vagrant@EdgeNode:~$ sudo crictl logs 2dbcb21286734
[KAFKA] Broker not available, retrying in 5s... (1/10)
[KAFKA] Broker not available, retrying in 5s... (2/10)
[KAFKA] Broker not available, retrying in 5s... (3/10)
[KAFKA] Broker not available, retrying in 5s... (4/10)
[KAFKA] Broker not available, retrying in 5s... (5/10)
[KAFKA] Broker not available, retrying in 5s... (6/10)
[KAFKA] Broker not available, retrying in 5s... (7/10)
[KAFKA] Broker not available, retrying in 5s... (8/10)
[KAFKA] Broker not available, retrying in 5s... (9/10)
[KAFKA] Broker not available, retrying in 5s... (10/10)
[KAFKA] Failed to connect to Kafka broker after retries.
vagrant@EdgeNode:~$ sudo crictl ps -a | grep telemetry-collector
a76ebc6f8ee13       643de01e97857       2 minutes ago       Exited              collector                6                   e59ea0b252b07       telemetry-collector-fkt5c
ffda73b7280ea       ff7a7936e9306       10 minutes ago      Exited              veth-setup               0                   e59ea0b252b07       telemetry-collector-fkt5c
vagrant@EdgeNode:~$ sudo crictl logs a76ebc6f8ee13
[WARN] Kafka broker not available, retrying in 5s (1/5)...: NoBrokersAvailable
[WARN] Kafka broker not available, retrying in 5s (2/5)...: NoBrokersAvailable
[WARN] Kafka broker not available, retrying in 5s (3/5)...: NoBrokersAvailable
[WARN] Kafka broker not available, retrying in 5s (4/5)...: NoBrokersAvailable
[WARN] Kafka broker not available, retrying in 5s (5/5)...: NoBrokersAvailable
[ERROR] Could not connect to Kafka after retries.

# then,
export BROKER_ADDR="192.168.56.121:31290"

# -- security-enforcement-agent ------------------------------------
kubectl -n edge-agents patch ds security-enforcement-agent \
  --type=json -p="[{
    \"op\":\"replace\",
    \"path\":\"/spec/template/spec/containers/0/env/0/value\",
    \"value\":\"${BROKER_ADDR}\"
}]"

# -- telemetry-collector -------------------------------------------
#  env list: 0=MQTT_BROKER_HOST, 1=MQTT_BROKER_PORT, 2=MQTT_TOPIC,
#            3=KAFKA_BOOTSTRAP   << we replace this one
kubectl -n edge-agents patch ds telemetry-collector \
  --type=json -p="[{
    \"op\":\"replace\",
    \"path\":\"/spec/template/spec/containers/0/env/3/value\",
    \"value\":\"${BROKER_ADDR}\"
}]"

kubectl -n edge-agents delete pod -l app=security-agent
kubectl -n edge-agents delete pod -l app=telem-collector

kubectl -n edge-agents get pods -w -o wide
#############################################################
############################################################
