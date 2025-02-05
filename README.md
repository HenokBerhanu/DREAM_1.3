# DREAM: Kubernetes Cluster for DIAM Architecture Implementation

This repository contains the configuration and scripts necessary to set up a three-node Kubernetes (K8s) cluster using Vagrant (v2.4.3) and VirtualBox(v7.0.24). The cluster is designed to implement the DIAM architecture, with one master node and two worker node.

The first worker node is the CoudNode which handles the application and control plane of the SDN architecture, while the second worker node is the EdgeNode where KubeEdge will be setup as an edge orchestrator. Agents that are required for the edge node will deployed as pod to communicate with the edge devices using MQTT message broker.

## Prerequisites

Before you begin, ensure you have the following installed on your host machine:

- [Vagrant](https://www.vagrantup.com/downloads)
- [VirtualBox](https://www.virtualbox.org/wiki/Downloads)

## Getting Started

1. **Clone the Repository**

   ```bash
   git clone https://github.com/HenokBerhanu/DREAM.git
   cd DREAM
   ```

2. **Start the Vagrant Environment**

   Run the following command to set up and start the virtual machines:

   ```bash
   vagrant up
   ```

   This command will:

   - Create three virtual machines: one master node and two worker nodes.
   - Provision each machine using the provided shell scripts to configure the system for Kubernetes.

3. **Access the Master Node**

   To interact with the Kubernetes cluster, SSH into the master node:

   ```bash
   vagrant ssh MasterNode
   ```

   From here, you can use `kubectl` to manage your cluster.

## Configuration Details

- **Vagrantfile**: Defines the configuration for the virtual machines, including provisioning steps and network settings.

- **Provisioning Scripts**: Located in the `configs` directory, these scripts perform various setup tasks:
  - `verify_certificate.sh`: Verifies SSL/TLS certificates for Kubernetes components.
  - `setup_kernel.sh`: Configures the kernel with the necessary modules and network settings for Kubernetes.
  - `setup_dns.sh`: Sets the system to use Google's DNS server.
  - `setup_hosts.sh`: Updates the `/etc/hosts` file to ensure proper name resolution between nodes.

- **tmux Configuration**: A `.tmux.conf` file is provided to enhance the terminal multiplexing experience. It is automatically placed in the home directory of the `vagrant` user during provisioning.

## Notes

- Ensure that your system has sufficient resources to run three virtual machines simultaneously.
- The provisioning scripts are designed for Ubuntu-jammy systems. If you are using a different base box, you may need to adjust the scripts accordingly.

## Troubleshooting

If you encounter issues during the setup process:

- Check the output of the `vagrant up` command for any error messages.
- Ensure that VirtualBox and Vagrant are both updated to their latest versions.
- Consult the [Vagrant documentation](https://www.vagrantup.com/docs) for additional guidance.
