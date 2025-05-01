# cd Telemetry-Collector-Agent/
# docker build -t henok/telemetry-collector:v4 .
# docker tag henok/telemetry-collector:v4 henok28/telemetry-collector:v4
# docker push henok28/telemetry-collector:v4

vagrant ssh-config MasterNode

# coppy from the host to the edge node
sudo scp -i /home/henok/DREAM_1.3/Kubernetes-deplyment/.vagrant/machines/MasterNode/virtualbox/private_key \
-P 2222 \
~/DREAM_1.3/Telemetry-Collector-Agent/telemetry_collector_daemonset.yaml \
vagrant@127.0.0.1:/home/vagrant/


kubectl apply -f telemetry_collector_daemonset.yaml
kubectl rollout restart daemonset telemetry-collector -n edge-agents
kubectl get pods -n edge-agents -w
# wait for the pod to appear on the edge node
kubectl -n edge-agents get pods -l app=telem-collector -o wide

# tail its log
kubectl -n edge-agents logs -l app=telem-collector -f

/etc/kubeedge/cloudcore.yaml
yaml\nmodules:\n cloudStream:\n enable: true # ← turn on\n streamPort: 10003 # (defaults ok)\n tunnelPort: 10350 # same as commonConfig.tunnelPort\n

# check on the edge node
sudo ctr -n k8s.io containers list | grep telemetry-collector

kubectl apply -f telemetry_collector_daemonset.yaml
kubectl rollout restart daemonset telemetry-collector -n edge-agents
kubectl get pods -n edge-agents -w


# Do a quick smoke-test
# Verify the health endpoint
# We are using mosquitto locally in the edge node (127.0.0.1:1883)
mosquitto_pub -h 127.0.0.1 -p 1883 -t devices/bed_sensor -m '{"device":"bed_sensor", "status":"normal", "timestamp": "2025-04-29T00:35:00Z"}'
# Try alert payload
mosquitto_pub -h 127.0.0.1 -p 1883 -t devices/infusion_pump -m '{"device":"infusion_pump", "status":"alert", "mac":"00:11:22:33:44:55"}'

# On the master node
kubectl -n kafka exec -it kafka-cluster-kafka-0 -- \
  bin/kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic telemetry-raw \
  --from-beginning

# See the alert topic
kubectl -n kafka exec -it kafka-cluster-kafka-0 -- \
  bin/kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic telemetry-alerts \
  --from-beginning

# Confirm Prometheus Metrics on the edge node
curl http://127.0.0.1:8080/metrics
# or
curl http://192.168.56.122:8080/metrics

#######################
vagrant@EdgeNode:~$ mosquitto_pub -h 127.0.0.1 -p 1883 -t devices/bed_sensor -m '{"device_id":"bed01","status":"ok"}'
vagrant@EdgeNode:~$ curl http://127.0.0.1:8080/metrics | grep telemetry
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  2569  100  2569    0     0   863k      0 --:--:-- --:--:-- --:--:-- 1254k
# HELP telemetry_messages_forwarded_total Total telemetry messages forwarded to Kafka
# TYPE telemetry_messages_forwarded_total counter
telemetry_messages_forwarded_total 1.0
# HELP telemetry_messages_forwarded_created Total telemetry messages forwarded to Kafka
# TYPE telemetry_messages_forwarded_created gauge
telemetry_messages_forwarded_created 1.7458881177970486e+09
vagrant@EdgeNode:~$ mosquitto_pub -h 127.0.0.1 -p 1883 -t devices/infusion_pump -m '{"device_id":"pump02","status":"alert"}'
vagrant@EdgeNode:~$ curl http://127.0.0.1:8080/metrics | grep alert
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  2555  100  2555    0     0   968k      0 --:--:-- --:--:-- --:--:-- 1247k
# HELP alerts_detected_total Total alert messages forwarded to Kafka
# TYPE alerts_detected_total counter
alerts_detected_total 1.0
# HELP alerts_detected_created Total alert messages forwarded to Kafka
# TYPE alerts_detected_created gauge
alerts_detected_created 1.7458881177970593e+09

#####################

# Coppy the required files from the host machine to the edge node
# Get ssh info from the edge core and get the private key directory
vagrant ssh-config EdgeNode

# coppy from the host to the edge node
sudo scp -i /home/henok/DREAM_1.3/Kubernetes-deplyment/.vagrant/machines/EdgeNode/virtualbox/private_key \
-P 2201 \
~/DREAM_1.3/virtual-devices/test_mqtt.py \
vagrant@127.0.0.1:/home/vagrant/

# on the edge node
    # pip install paho-mqtt
    # python3 test_mqtt.py
    # then confirm entries
        curl http://127.0.0.1:8080/metrics | grep -E 'telemetry|alerts'

###################
python3 test_mqtt.py
Sending test messages...

[Bed Sensor] hospital/bed_sensor: {"device_id": "bed_sensor_01", "timestamp": 1745892079, "occupancy": 0}
[ECG Monitor] hospital/ecg_monitor: {"device_id": "ecg_monitor_01", "timestamp": 1745892080, "heart_rate": 66, "rhythm": "Normal"}
[Infusion Pump] hospital/infusion_pump: {"device_id": "infusion_pump_01", "timestamp": 1745892081, "flow_rate": 58.28, "status": "running"}
[Ventilator] hospital/ventilator: {"device_id": "ventilator_01", "timestamp": 1745892082, "respiratory_rate": 14, "tidal_volume": 346.5, "status": "operational"}
[Wheelchair] hospital/wheelchair: {"device_id": "wheelchair_01", "timestamp": 1745892083, "location": {"room": 119, "floor": 1}, "battery_level": 98, "status": "in-use"}
[ALERT (ventilator)] hospital/ventilator: {"device_id": "ventilator_01", "timestamp": 1745892084, "status": "alert"}

Done.
vagrant@EdgeNode:~$ curl http://127.0.0.1:8080/metrics | grep -E 'telemetry|alerts'
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  2570  100  2570    0     0  1014k      0 --:--:-- --:--:-- --:--:-- 1254k
# HELP telemetry_messages_forwarded_total Total telemetry messages forwarded to Kafka
# TYPE telemetry_messages_forwarded_total counter
telemetry_messages_forwarded_total 2.0
# HELP telemetry_messages_forwarded_created Total telemetry messages forwarded to Kafka
# TYPE telemetry_messages_forwarded_created gauge
telemetry_messages_forwarded_created 1.7458881177970486e+09
# HELP alerts_detected_total Total alert messages forwarded to Kafka
# TYPE alerts_detected_total counter
alerts_detected_total 1.0
# HELP alerts_detected_created Total alert messages forwarded to Kafka
# TYPE alerts_detected_created gauge
alerts_detected_created 1.7458881177970593e+09
#######################


# verify that your Telemetry Collector agent is indeed using the external listener (NodePort 9094) to talk to Kafka,
# Check the environment variables of the Telemetry Collector Pod
kubectl -n edge-agents describe pod $(kubectl -n edge-agents get pod -l app=telem-collector -o jsonpath='{.items[0].metadata.name}') \
  | grep -A 10 "KAFKA_BOOTSTRAP"
          # Output
    #       KAFKA_BOOTSTRAP:          192.168.56.121:31896
    #       KAFKA_SECURITY_PROTOCOL:  PLAINTEXT
    #       TOPIC_RAW:                telemetry-raw
    #       TOPIC_ALERTS:             telemetry-alerts
    #     Mounts:
    #       /dev from dev-mount (rw)
    #       /var/run/openvswitch from ovsdb-socket (rw)
    #       /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-nl2xh (ro)
    # Conditions:
    #   Type                        Status
    #   PodReadyToStartContainers   True 

# Check the logs of the collector container





