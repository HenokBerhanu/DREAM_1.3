# Kubernetes Cluster for DIAM Architecture Implementation

This repository provides everything you need to set up a **three-node Kubernetes (K8s) cluster** using **Vagrant v2.4.3** and **VirtualBox v7.0.24**. The cluster supports the **DIAM (Distributed Intelligent Additive Manufacturing)** architecture with a Cloud-Edge deployment model.

The cluster comprises:
- **1 Master Node**: Controls the Kubernetes control plane
- **1 Cloud Worker Node**: Runs application and control plane services (e.g., ONOS SDN Controller, microservices)
- **1 Edge Node**: Runs KubeEdge, Open vSwitch (OVS), and device-facing agents to simulate edge computing for DIAM

---

## 📝 Prerequisites
Ensure the following are installed on your **host machine**:

- [Vagrant](https://www.vagrantup.com/downloads)
- [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
- Host: Ubuntu Jammy

---

## 🚀 Getting Started

### 1. Clone the Repository
```bash
git clone https://github.com/HenokBerhanu/DREAM_1.3.git
cd DREAM_1.3
```

### 2. Bring Up the Cluster
```bash
vagrant up
```
This will:
- Create three VMs: `MasterNode`, `CloudNode`, and `EdgeNode`
- Run provisioning scripts to:
  - Install container runtimes (containerd)
  - Set up Kubernetes and networking
  - Initialize the master node using `kubeadm`
  - Join worker nodes to the cluster

> ⚠️ This process may take a few minutes depending on your system.

### 3. Access the Cluster
```bash
vagrant ssh MasterNode
```
Once inside:
```bash
kubectl get nodes
```
You should see:
```
NAME         STATUS   ROLES           AGE   VERSION
masternode   Ready    control-plane   ...   v1.29.15
cloudnode    Ready    worker-node     ...   v1.29.15
edgenode     Ready    agent,edge      ...   v1.30.7-kubeedge-v1.20.0
```

---

## 🔧 Cluster Configuration Details

### 📂 Vagrantfile
Defines the VM structure:
- Node hostnames
- Static IPs (192.168.56.102/121/122)
- Network adapters
- Node roles (master, cloud, edge)

### 📚 Provisioning Scripts (in `configs/`)
| Script             | Description |
|--------------------|-------------|
| `setup_kernel.sh`  | Loads kernel modules and sysctl params |
| `setup_hosts.sh`   | Adds hostname mappings to `/etc/hosts` |
| `setup_dns.sh`     | Sets DNS resolver to 8.8.8.8            |
| `verify_certificate.sh` | Verifies Kubernetes TLS artifacts  |
| `install_containerd.sh` | Installs and configures containerd  |
| `init_kube_master.sh`   | Runs `kubeadm init` on MasterNode   |
| `join_worker.sh`        | Runs `kubeadm join` on Cloud and Edge nodes |

> 🚨 `EdgeNode` is excluded from CNI and is configured with OVS for SDN use.

---

## 🔍 Post-Setup Overview

### 🚜 Master + Cloud Nodes
- Use **Flannel CNI** for intra-cluster networking
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

### Check OVS Connection from Edge Node
```bash
sudo ovs-vsctl show
```
Ensure `Controller "tcp://192.168.56.103:6653"` is shown for `br0`.

---

## 📅 Recommendations

- Allocate at least **6 CPUs and 8GB RAM per worker VM and 4 CPUs and 4GB RAM for master node** for smooth deployment.
- Use **Ubuntu-jammy base image** (default in this repo).
- Ensure host system has virtualization extensions enabled (e.g., VT-x/AMD-V).

---

## 🔧 Tmux Configuration
- `.tmux.conf` is provisioned to each VM for pane synchronization and improved terminal multiplexing.

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

## ⚠️ Troubleshooting

- Reboot the VMs if `kubeadm join` hangs (EdgeNode might boot slowly)
- Re-run `vagrant provision` if setup scripts fail
- Check `kubelet`, `containerd`, and `flanneld` logs via `journalctl -u ...`
- Ensure port 6443 (K8s API) and 6653 (OpenFlow) are accessible between nodes

---

## 📖 References
- [Kubernetes Docs](https://kubernetes.io/docs/)
- [Vagrant Docs](https://developer.hashicorp.com/vagrant/docs)
- [ONOS Controller](https://opennetworking.org/onos/)
- [KubeEdge](https://kubeedge.io/)

---