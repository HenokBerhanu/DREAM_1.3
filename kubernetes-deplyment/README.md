# Kubernetes Cluster for DIAM Architecture Implementation

This repository provides everything you need to set up a **Kubernetes (K8s) cluster**. The cluster supports the **DIAM (Distributed Intelligent Additive Manufacturing)** architecture with a Cloud-Edge deployment model.

The cluster comprises:
- * Master Node**: Controls the Kubernetes control plane
- * Cloud Worker Node**: Runs application and control plane microservices (e.g., ONOS SDN Controller and application plane microservices)
- * Local Edge Node**: Runs KubeEdge, Open vSwitch (OVS), and smart IoT device corresponding to AM

---

## 📝 Prerequisites
- Nodes: Ubuntu Jammy 
- Nodes should be either in the same subnet or connected VPN for seamless tunnelling

---

## 🚀 Getting Started

### 1. Clone the Repository for all the nodes
```bash
git clone https://github.com/IoT-Lab-UNM/DREAM-Scalable-MaaS.git
cd DREAM-Scalable-MaaS
```

### 2. Bring Up the Cluster

Setup:
- The three nodes: `MasterNode`, `CloudNode`, and `EdgeNode`
- go to the k8s website to setup each nodes: https://kubernetes.io/ or follow:
- /kubernetes-deplyment/notes/node-setup_v1.28.sh or /kubernetes-deplyment/notes/node-setup_v1.29.sh or /kubernetes-deplyment/notes/node-setup_v1.33.sh (We are using v33)

### 3. Access the Cluster

from the master node:
```bash
kubectl get nodes
```
You should see outputs like this:
```
NAME         STATUS   ROLES           AGE   VERSION
masternode   Ready    control-plane   ...   v1.29.15
cloudnode    Ready    worker-node     ...   v1.29.15
edgenode     Ready    agent,edge      ...   v1.30.7-kubeedge-v1.20.0
```

---

## 🔧 Cluster Configuration Details

### 📚 Provisioning Scripts (in `configs/`)
| Script             | Description |
|--------------------|-------------|
| `setup_kernel.sh`  | Loads kernel modules and sysctl params |
| `setup_hosts.sh`   | Adds hostname mappings to `/etc/hosts` |
| `setup_dns.sh`     | Sets DNS resolver to 8.8.8.8            |
| `verify_certificate.sh` | Verifies Kubernetes TLS artifacts  |

> 🚨 `EdgeNode` is excluded from CNI and is configured with OVS for SDN and edge environment use.

---

## 🔍 Post-Setup Overview

### 🚜 Master + Cloud Nodes
- Use **Flannel/Calico CNI** for intra-cluster networking
- Host ONOS controller, predictive maintenance, and policy manager microservices

### 🏠 Edge Node
- **No CNI plugin** (excluded by label)
- OVS bridge (`br0`) configured
- Connected to ONOS via `tcp://<onos-ip>:6653`
- Hosts simulated devices (pods) manually connected to OVS via veth
- Runs KubeEdge agents

---

## ⚖️ Testing and Validation

### Verify Node Status
```bash
kubectl get nodes -o wide
```

### Check Cluster Services
```bash
kubectl get pods -A
```

## 📅 Recommendations

- Allocate at least **6 CPUs and 8GB RAM per nodes** for smooth deployment.
- Use **Ubuntu-jammy base image** (default in this repo).
- Ensure host system has virtualization extensions enabled (e.g., VT-x/AMD-V).

---

## ⚠️ Troubleshooting

- Reboot the nodes if `kubeadm join` hangs (EdgeNode might boot slowly)
- Check `kubelet`, `containerd`, and `flanneld`/ `calico` logs via `journalctl -u ...`
- Ensure port 6443 (K8s API) and 6653 (OpenFlow - SBI) are accessible between nodes

---

## 📖 References
- [Kubernetes Docs](https://kubernetes.io/docs/)
- [ONOS Controller](https://opennetworking.org/onos/)
- [KubeEdge](https://kubeedge.io/)

---