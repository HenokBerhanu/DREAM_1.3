curl -u onos:rocks -X POST \
  http://192.168.56.121:30181/onos/v1/applications/org.onosproject.openflow/active


kubectl delete -f onos_deployment.yaml


sudo ovs-vsctl del-controller br0 || true
sudo ovs-vsctl del-br br0 || true
sudo ovs-vsctl add-br br0
