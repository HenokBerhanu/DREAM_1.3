# docker build -t your-dockerhub-username/security-agent .
# docker push your-dockerhub-username/security-agent

# setup veth Binding
# This makes veth-sec available in the hostNetwork namespace and veth-br-sec part of the br0 bridge.
sudo ip link add veth-sec type veth peer name veth-br-sec
sudo ip link set veth-br-sec up
sudo ip link set veth-sec up
sudo ovs-vsctl add-port br0 veth-br-sec

# cd Security-Enforcement-Agent/
# docker build -t henok28/security-enforcement-agent:latest .
# docker push henok28/security-enforcement-agent:latest

# docker build -t henok/onos-diam:v3 .
# Login to docker
# Logout if you are logged in to the required account
    # docker logout
    # docker login
    #         put your username and password
# docker tag henok/onos-diam:v3 henok28/onos-diam:v3
# docker push henok28/onos-diam:v3