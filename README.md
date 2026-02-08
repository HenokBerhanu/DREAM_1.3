### Scalable DIAM Network Architecture for Multi-Site MaaS between UNM, NMSU, NMT, and NTU

This repo is dedicated to:

* Implements a multi-site Manufacturing-as-a-Service (MaaS) workflow where a remote client submits a print order to the CloudNode, which selects the best site/printer under policy + SLA constraints.​
* Defines a CloudNode application and control plane microservices: Web Order App, Marketplace, Job Manager, Policy Management System, SLA Intelligence, and SDN controller.​
* Establishes a closed-loop design: Telemetry Agent streams health/queue/RTT/progress back to cloud services (SLA Intelligence + Job Manager) for continuous re-scoring and decisions.​
* Adds an edge-side Security Enforcement Agent that applies cloud- derived ACL/QoS policies at the edge to protect and segment job traffic.

---
<img src="figs/DREAM_MaaS_Busines_Model.gif" width="600" alt="DIAM Network Architecture for Multi-Site MaaS (GIF)">
<!-- ![DIAM Network Architecture for Multi-Site MaaS webm](figs/DREAM_MaaS_Busines_Model.gif) -->

---
<img src="figs/MaaS.png" width="600" alt="DIAM Network Architecture for Multi-Site MaaS (PNG)">
<!-- ![DIAM Network Architecture for Multi-Site MaaS png](figs/MaaS.png) -->

---
<img src="figs/Local_MaaS.jpeg" width="600" alt="Local MaaS testbed">
<!-- ![Local MaaS testbed](figs/Local_MaaS.jpeg) -->


### Check OVS Connection from Edge Node
```bash
sudo ovs-vsctl show
```
Ensure `Controller "tcp://192.168.56.103:6653"` is shown for `br0`.

---

## ⚡ Interactive Edge Deployment Steps (Optional)
Once the cluster is up:

### 1. SSH into Edge Node
```bash
vagrant ssh EdgeNode
```

### 2. Set Up OVS
```bash
sudo ovs-vsctl add-br br0
sudo ovs-vsctl set-controller br0 tcp://192.168.56.103:6653
```

### 3. Manually Connect Pods to OVS
Use `attach-pod-to-ovs.sh` to bridge pod veth to `br0`.

---