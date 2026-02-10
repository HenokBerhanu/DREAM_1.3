### Scalable DIAM Network Architecture for Multi-Site MaaS between UNM, NMSU, NMT, and NTU

This repo is dedicated to:

* Implements a multi-site Manufacturing-as-a-Service (MaaS) workflow where a remote client submits a print order to the CloudNode, which selects the best site/printer under policy + SLA constraints.​
* Defines a CloudNode application and control plane microservices: Web Order App, Marketplace, Job Manager, Policy Management System, SLA Intelligence, and SDN controller.​
* Establishes a closed-loop design: Telemetry Agent streams health/queue/RTT/progress back to cloud services (SLA Intelligence + Job Manager) for continuous re-scoring and decisions.​
* Adds an edge-side Security Enforcement Agent that applies cloud- derived ACL/QoS policies at the edge to protect and segment job traffic.


## Start setup
### First deply k8s cluster for network orchestration:

Follow the readme file in the this directory to setup k8s cluster: /kubernetes-deplyment/README.md
---
<img src="figs/DREAM_MaaS_Busines_Model.gif" width="600" alt="DIAM Network Architecture for Multi-Site MaaS (GIF)">
<!-- ![DIAM Network Architecture for Multi-Site MaaS webm](figs/DREAM_MaaS_Busines_Model.gif) -->

---
<img src="figs/MaaS.png" width="600" alt="DIAM Network Architecture for Multi-Site MaaS (PNG)">
<!-- ![DIAM Network Architecture for Multi-Site MaaS png](figs/MaaS.png) -->

---
<img src="figs/Local_MaaS.jpeg" width="600" alt="Local MaaS testbed">
<!-- ![Local MaaS testbed](figs/Local_MaaS.jpeg) -->
