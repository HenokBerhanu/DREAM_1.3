1. Telemetry Ingestion

A “Telemetry Collector Agent” on the edge subscribes to IoT device MQTT topics, normalizes messages, and pushes into Kafka. 
The telemetry-collector DaemonSet already does this via MQTT → Kafka.

2. Anomaly / Policy Decision (Policy‐Management Service)

Telemetry feeds analytics (fault-detector, predictive maintenance…), then a “Policy Management System” issues high-level enforcement rules via REST.
The policy-manager Deployment exposes REST endpoints (e.g. POST /policies).

Policy Management System:
   Consumes Kafka alerts/topics (e.g. telemetry-alerts).
   Transforms into flow rules.
   Invokes the Security Enforcement Agent’s REST API (POST http://<sec-agent>/api/flows).

3. Enforcement (Security Enforcement Agent)

Receives rules and programs OVS via OpenFlow, emitting Prometheus metrics.

security-enforcement-agent exposes:
   POST /api/flows to receive new rules
   /metrics on port 9000 for Prometheus

4. Visualization (Asset-Monitoring Dashboard + Grafana + Prometheus)

dashboard pulls from Kafka (raw and alert streams), Grafana dashboards query Prometheus metrics (latency, blocks, CPU).

setup:
  asset-monitoring-dashboard reads Kafka and displays via Flask+Chart.js.
  prometheus scrapes both itself and the agent’s /metrics
  grafana points at prometheus as a data source.

  #####################################
  Test
  ######################################

  A. Telemetry ingestion test (MQTT → Kafka)
  # Test whether the mqtt broker is collecting data from the data plane devices
  mosquitto_sub -t devices/bed_sensor -h localhost
     # Output
      {"device_id": "bed_sensor_01", "device_mac": "00:11:22:33:44:11", "timestamp": 1747240076, "sensor_readings": [0, 0, 0, 0, 0, 0], "status": "vacant"}
      {"device_id": "bed_sensor_02", "device_mac": "00:11:22:33:44:12", "timestamp": 1747240078, "sensor_readings": [1, 0, 0, 0, 0, 0], "status": "occupied"}
      {"device_id": "bed_sensor_03", "device_mac": "00:11:22:33:44:13", "timestamp": 1747240080, "sensor_readings": [0, 0, 0, 0, 0, 0], "status": "vacant"}
      {"device_id": "bed_sensor_01", "device_mac": "00:11:22:33:44:11", "timestamp": 1747240087, "sensor_readings": [0, 0, 0, 0, 0, 0], "status": "vacant"}
      {"device_id": "bed_sensor_02", "device_mac": "00:11:22:33:44:12", "timestamp": 1747240089, "sensor_readings": [1, 0, 0, 0, 0, 0], "status": "occupied"}

  # Watch your Telemetry Collector logs to confirm it picked it up and wrote to Kafka.
  sudo crictl ps -a | grep telemetry-collector
      # output
      05eb371e3b5e2       643de01e97857       24 minutes ago      Running             collector                8                   1ef9f3ccfb311       telemetry-collector-zm2x9
      6cdfbbe994b36       643de01e97857       25 minutes ago      Exited              collector                7                   1ef9f3ccfb311       telemetry-collector-zm2x9
      9cbcb2b54c51c       ff7a7936e9306       26 minutes ago      Exited              veth-setup               3                   1ef9f3ccfb311       telemetry-collector-zm2x9

  sudo crictl logs 05eb371e3b5e2
      # Output
      [KAFKA] Producer connected successfully.
      Starting Telemetry-Collector — MQTT 127.0.0.1:1883  ⇒  Kafka 192.168.56.121:31290
      [MQTT] Connected with result code 0 — subscribing to devices/#
      [OK] devices/ventilator → Kafka
      [OK] devices/infusion_pump → Kafka
      [OK] devices/wheelchair → Kafka
      [OK] devices/ecg_monitor → Kafka
      [OK] devices/bed_sensor → Kafka

B. Policy run-through (Kafka alert → Policy Manager → Sec Agent)

# Check the KAFKA service address
kubectl -n microservices run dns-test \
  --rm -it \
  --image=busybox \
  --restart=Never \
  --overrides='
{
  "apiVersion": "v1",
  "spec": {
    "nodeName": "cloudnode"
  }
}' \
  -- sh
# From inside that shell, verify DNS and TCP: nslookup should resolve to 10.108.211.119 (your ClusterIP). and nc -vz … 9092 should succeed:
/ # nslookup kafka-cluster-kafka-bootstrap.kafka.svc.cluster.local
/ # nc -vz kafka-cluster-kafka-bootstrap.kafka.svc.cluster.local 9092

# Check 

sudo crictl ps -a | grep security-enforcement-agent
  #Output
  0b57bfe85aec9       33f2cb1f3975d       27 minutes ago      Running             enforcement-agent        2                   e93d93e48e894       security-enforcement-agent-s24vv
  ae7f7c2acaa55       33f2cb1f3975d       28 minutes ago      Exited              enforcement-agent        1                   e93d93e48e894       security-enforcement-agent-s24vv
  ac970f67ef4e3       ff7a7936e9306       28 minutes ago      Exited              veth-setup               1                   e93d93e48e894       security-enforcement-agent-s24vv
sudo crictl logs 0b57bfe85aec9