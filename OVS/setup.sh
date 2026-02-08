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