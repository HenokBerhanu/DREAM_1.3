#!/bin/bash
set -e

# Set OpenFlow listener and force IPv4
export JAVA_OPTS="-Djava.net.preferIPv4Stack=true -Dorg.onosproject.openflow.address=0.0.0.0"

# Run ONOS in foreground
exec /root/onos/apache-karaf-*/bin/karaf run