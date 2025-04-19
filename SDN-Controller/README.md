# ONOS + OVS + KubeEdge Integration Guide

This README documents the end-to-end process of integrating **ONOS (Open Network Operating System)** with **Open vSwitch (OVS)** in a **Kubernetes + KubeEdge hybrid cluster**. It includes setup, troubleshooting, diagnostics, and successful configuration verification.

---

## 📍 System Overview

- **Cluster Nodes**:
  - `MasterNode` — Kubernetes Master (Flannel CNI)
  - `CloudNode` — Runs ONOS as a Pod
  - `EdgeNode` — KubeEdge-enabled, runs OVS

- **ONOS Controller**:
  - Runs as a Kubernetes Pod in the `micro-onos` namespace on the `CloudNode`
  - Listens on port **6653** for OpenFlow

- **OVS Switch**:
  - Runs on EdgeNode (standalone)
  - Uses OpenFlow 1.3 protocol

---

## ✅ Final Working Snapshot

```sh
$ kubectl exec -n micro-onos -it $(kubectl get pods -n micro-onos -l app=onos -o name) -- /bin/bash
$ /root/onos/apache-karaf-*/bin/client
karaf@root > devices
id=of:0000000000000001, available=true, ...

karaf@root > ports
port=LOCAL, state=enabled, ...
port=2, state=enabled, portName=veth0

karaf@root > flows
id=..., selector=[ETH_TYPE:lldp], treatment=[OUTPUT:CONTROLLER]
```
---

## 📘 Deployment Steps

### 1. Build and Push ONOS Docker Image
```Dockerfile
FROM onosproject/onos:latest
USER root
RUN apt-get update && apt-get install -y net-tools iputils-ping curl procps
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
WORKDIR /root/onos
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
```
```bash
# entrypoint.sh
#!/bin/bash
export JAVA_OPTS="-Djava.net.preferIPv4Stack=true -Dorg.onosproject.openflow.address=0.0.0.0"
exec /root/onos/apache-karaf-*/bin/start
```

### 2. ONOS Deployment YAML
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: onos-controller
  namespace: micro-onos
spec:
  replicas: 1
  selector:
    matchLabels:
      app: onos
  template:
    metadata:
      labels:
        app: onos
    spec:
      nodeSelector:
        kubernetes.io/hostname: cloudnode
      hostNetwork: true
      containers:
      - name: onos
        image: henok28/onos-diam:v2
        ports:
        - containerPort: 6653
        env:
        - name: ONOS_APPS
          value: openflow,gui
```

### 3. Deploy OVS on EdgeNode
```bash
sudo apt install openvswitch-switch
sudo systemctl start openvswitch-switch
```

#### Reset and Configure Bridge
```bash
sudo ovs-vsctl del-controller br0
sudo ovs-vsctl del-br br0
sudo ovs-vsctl add-br br0
sudo ovs-vsctl set bridge br0 other-config:datapath-id=0000000000000001
sudo ovs-vsctl set bridge br0 protocols=OpenFlow13
sudo ip link set br0 up
```

#### Add Dummy Interface
```bash
sudo ip link add veth0 type veth peer name veth1
sudo ip link set veth0 up
sudo ip link set veth1 up
sudo ovs-vsctl add-port br0 veth0
```

#### Connect to ONOS Controller
```bash
sudo ovs-vsctl set-controller br0 tcp://192.168.56.121:6653
```

---

## 🔍 Troubleshooting

### 1. Check TCP Connection
```bash
telnet 192.168.56.121 6653
```

### 2. Monitor OpenFlow Packets
```bash
sudo tcpdump -i any port 6653 -nn
```

### 3. Verify Flow Exchange
```bash
sudo ovs-ofctl -O OpenFlow13 show br0
```

### 4. Access ONOS CLI
```bash
kubectl exec -n micro-onos -it <onos-pod> -- /root/onos/apache-karaf-*/bin/client
```

### 5. Commands in ONOS CLI
```bash
devices
ports
flows
apps -a -s
```

---

## 📝 Notes
- ONOS and OVS must both support **OpenFlow 1.3**
- ONOS must run with `hostNetwork: true` if using Flannel or other non-routable CNIs
- Ensure the EdgeNode can reach ONOS Pod IP or NodePort from outside the K8s overlay
- KubeEdge **does not require** CNI to function, but limits pod deployment on the edge
- OVS running on the edge **communicates directly** with ONOS via physical interface

---

## 📚 Citations & References
- [ONOS Official GitHub](https://github.com/opennetworkinglab/onos)
- [ONOS-Kubernetes Examples](https://github.com/opennetworkinglab/onos-kubernetes)
- [KubeEdge Networking](https://kubeedge.io/)
- [KubeEdge Repo](https://github.com/kubeedge/kubeedge)
- [ONOS Documentation](https://wiki.onosproject.org/display/ONOS)
- [Open vSwitch Docs](https://docs.openvswitch.org/en/latest/)

---

---

## 📦 Future Enhancements
- Add automatic health monitoring via Prometheus
- Integrate ONOS REST API dashboard to visualize topology
- Replace dummy ports with IoT devices or digital twins for DIAM testbed

---

> “Struggled for days, connected in minutes. Document every step.”

