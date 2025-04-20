curl -u onos:rocks -X POST \
  http://192.168.56.121:30181/onos/v1/applications/org.onosproject.openflow/active


kubectl delete -f onos_deployment.yaml


sudo ovs-vsctl del-controller br0 || true
sudo ovs-vsctl del-br br0 || true
sudo ovs-vsctl add-br br0


sudo ovs-vsctl show
      # output
      Bridge "br0"
        Controller "tcp://192.168.56.103:30653"
          is_connected: true

##############################################################
##############################################################
                # Start here
##############################################################
# Start over
# Delete the ONOS Pod
kubectl delete deployment onos-controller -n micro-onos
kubectl delete service onos-service -n micro-onos
      # Verify:
      kubectl get pods -n micro-onos

# edge node
sudo ovs-vsctl del-controller br0
sudo ovs-vsctl del-br br0
sudo ip link delete veth0
sudo ip link delete veth1
    # check its gone
    sudo ovs-vsctl show

# Recreate the ONOS Controller (CloudNode)
kubectl apply -f onos_deployment.yaml
# Check logs:
kubectl logs -n micro-onos -l app=onos --tail=50 -f

# Activate openflow from the cloud node where onos is installed
curl -u onos:rocks -X POST \
  http://192.168.56.121:30181/onos/v1/applications/org.onosproject.openflow/active

# and then check the port and ip is listening or not
sudo netstat -tulnp | grep 6653

# Recreate OVS Bridge (EdgeNode)
sudo ovs-vsctl add-br br0
sudo ovs-vsctl set bridge br0 other-config:datapath-id=0000000000000001
sudo ovs-vsctl set bridge br0 protocols=OpenFlow13
sudo ip link add veth0 type veth peer name veth1
sudo ip link set veth0 up
sudo ip link set veth1 up
sudo ovs-vsctl add-port br0 veth0
sudo ip link set br0 up
sudo ovs-vsctl set-controller br0 tcp://192.168.56.121:6653
         # verify:
         sudo ovs-vsctl show
         sudo ovs-ofctl -O OpenFlow13 show br0


# these three lines of command were the key for the ovs to be registered to the openflow onos in the cloud node
# These three lines are really remarkable......
sudo ovs-vsctl set-controller br0 tcp:192.168.56.121:6653
sudo ovs-vsctl set bridge br0 protocols=OpenFlow13
sudo ovs-ofctl -O OpenFlow13 probe br0
#############################################################################################

###########################################################################################
# Check the device ID is registeed to ONOS CLI from the master node
###########################################################################################
kubectl exec -n micro-onos -it $(kubectl get pods -n micro-onos -l app=onos -o name) -- /bin/bash
root@CloudNode:~/onos# cd /root/onos/apache-karaf-4.2.14/bin
root@CloudNode:~/onos/apache-karaf-4.2.14/bin# ./client
Logging in as karaf
Welcome to Open Network Operating System (ONOS)!
     ____  _  ______  ____     
    / __ \/ |/ / __ \/ __/   
   / /_/ /    / /_/ /\ \     
   \____/_/|_/\____/___/     
                               
Documentation: wiki.onosproject.org      
Tutorials:     tutorials.onosproject.org 
Mailing lists: lists.onosproject.org     

Come help out! Find out how at: contribute.onosproject.org 

Hit '<tab>' for a list of available commands
and '[cmd] --help' for help on a specific command.
Hit '<ctrl-d>' or type 'logout' to exit ONOS session.

karaf@root > devices
id=of:0000000000000001, available=true, local-status=connected 1m30s ago, role=MASTER, type=SWITCH, mfr=Nicira, Inc., hw=Open vSwitch, sw=2.17.9, serial=None, chassis=1, driver=ovs, channelId=192.168.56.122:55344, datapathDescription=None, managementAddress=192.168.56.122, protocol=OF_13
karaf@root > ports
id=of:0000000000000001, available=true, local-status=connected 1m36s ago, role=MASTER, type=SWITCH, mfr=Nicira, Inc., hw=Open vSwitch, sw=2.17.9, serial=None, chassis=1, driver=ovs, channelId=192.168.56.122:55344, datapathDescription=None, managementAddress=192.168.56.122, protocol=OF_13
  port=LOCAL, state=enabled, type=copper, speed=0 , adminState=enabled, portMac=72:8b:22:1e:7d:4c, portName=br0
  port=1, state=enabled, type=copper, speed=10000 , adminState=enabled, portMac=ea:89:9d:88:a5:8a, portName=veth0
karaf@root > flows
deviceId=of:0000000000000001, flowRuleCount=3
    id=100007a585b6f, state=ADDED, bytes=0, packets=0, duration=95, liveType=UNKNOWN, priority=40000, tableId=0, appId=org.onosproject.core, selector=[ETH_TYPE:bddp], treatment=DefaultTrafficTreatment{immediate=[OUTPUT:CONTROLLER], deferred=[], transition=None, meter=[], cleared=true, StatTrigger=null, metadata=null}
    id=100009465555a, state=ADDED, bytes=0, packets=0, duration=95, liveType=UNKNOWN, priority=40000, tableId=0, appId=org.onosproject.core, selector=[ETH_TYPE:lldp], treatment=DefaultTrafficTreatment{immediate=[OUTPUT:CONTROLLER], deferred=[], transition=None, meter=[], cleared=true, StatTrigger=null, metadata=null}
    id=10000ea6f4b8e, state=ADDED, bytes=0, packets=0, duration=95, liveType=UNKNOWN, priority=40000, tableId=0, appId=org.onosproject.core, selector=[ETH_TYPE:arp], treatment=DefaultTrafficTreatment{immediate=[OUTPUT:CONTROLLER], deferred=[], transition=None, meter=[], cleared=true, StatTrigger=null, metadata=null}
#######################################################################################################


#####################################################################################################
vagrant@MasterNode:~$ kubectl logs -n micro-onos -l app=onos | grep -i "connected\|device\|openflow"
04:55:18.137 INFO  [DeviceManager] Device of:0000000000000001 connected
04:55:18.138 INFO  [DeviceFlowTable] Activating term 1 for device of:0000000000000001
04:55:18.238 INFO  [TopologyManager] Topology DefaultTopology{time=6801808320481, creationTime=1745038518228, computeCost=670015, clusters=1, devices=1, links=0} changed
04:55:18.239 INFO  [InOrderFlowObjectiveManager] Driver ovs bound to device of:0000000000000001 ... initializing driver
04:55:18.340 INFO  [DeviceManager] Role has been acknowledged for device of:0000000000000001
04:55:18.340 INFO  [OpenFlowControllerImpl$OpenFlowSwitchAgent] Transitioned switch 00:00:00:00:00:00:00:01 to MASTER
04:55:18.340 INFO  [OpenFlowControllerImpl$OpenFlowSwitchAgent] Purged pending stats 00:00:00:00:00:00:00:01
04:55:19.335 INFO  [DistributedGroupStore] Group AUDIT: Setting device of:0000000000000001 initial AUDIT completed
vagrant@MasterNode:~$ 
#####################################################################################################