import json, os, subprocess, time, schedule, threading
import requests
from kafka import KafkaConsumer, KafkaProducer
from prometheus_client import start_http_server, Counter
from flask import Flask, jsonify
from collections import deque

# Prometheus metrics
alerts_processed = Counter('alerts_processed_total', 'Total security alerts processed')
flows_blocked = Counter('flows_blocked_total', 'Total MACs blocked')
flow_logging_runs = Counter('flow_log_scrapes_total', 'Times flow tables were logged')

# In-memory flow log buffer for UI
flow_log_store = deque(maxlen=100)
app = Flask(__name__)

@app.route("/api/flows")
def get_flows():
    return jsonify(list(flow_log_store))

# Start Prometheus metrics server
start_http_server(9000)

KAFKA_BROKER = os.getenv("KAFKA_BROKER", "kafka-service:9092")
ONOS_URL = os.getenv("ONOS_URL", "http://onos-service:8181")
BRIDGE = os.getenv("OVS_BRIDGE", "br0")
ENFORCE_MODE = os.getenv("ENFORCE_MODE", "onos")  # or "ovs"

# Kafka producer for logging
producer = KafkaProducer(
    bootstrap_servers=KAFKA_BROKER,
    value_serializer=lambda x: json.dumps(x).encode('utf-8')
)

def block_device(mac_address):
    flows_blocked.inc()
    print(f"[SECURITY] Enforcing block for MAC: {mac_address}")
    
    if ENFORCE_MODE == "onos":
        rule = {
            "priority": 40000,
            "isPermanent": True,
            "deviceId": "of:0000000000000001",
            "treatment": { "instructions": [] },
            "selector": {
                "criteria": [{"type": "ETH_SRC", "mac": mac_address}]
            }
        }
        response = requests.post(
            f"{ONOS_URL}/onos/v1/flows/of:0000000000000001",
            auth=("onos", "rocks"),
            json=rule
        )
        print(f"[ONOS] Flow Add Response: {response.status_code}")
    
    elif ENFORCE_MODE == "ovs":
        cmd = f"ovs-ofctl add-flow {BRIDGE} dl_src={mac_address},actions=drop"
        subprocess.run(cmd.split(), check=True)
        print("[OVS] Rule inserted via ovs-ofctl")

def process_alerts():
    consumer = KafkaConsumer(
        "security_alerts",
        bootstrap_servers=KAFKA_BROKER,
        value_deserializer=lambda x: json.loads(x.decode("utf-8"))
    )
    for msg in consumer:
        alert = msg.value
        alerts_processed.inc()
        print(f"[ALERT] {alert}")
        if alert.get("type") == "unauthorized_access":
            block_device(alert["mac"])

# Periodic flow table logger
def log_flows():
    print("[LOG] Dumping flow table...")
    flow_logging_runs.inc()
    
    if ENFORCE_MODE == "ovs":
        cmd = f"ovs-ofctl dump-flows {BRIDGE}"
        result = subprocess.run(cmd.split(), capture_output=True, text=True)
        flows = result.stdout.strip().split("\n")[1:]
        for flow in flows:
            log = {"bridge": BRIDGE, "flow": flow}
            flow_log_store.append(log)
            print("[FLOW-OVS]", log)
            producer.send("flow_logs", log)

    elif ENFORCE_MODE == "onos":
        response = requests.get(
            f"{ONOS_URL}/onos/v1/flows/of:0000000000000001",
            auth=("onos", "rocks")
        )
        if response.status_code == 200:
            data = response.json()
            for f in data.get("flows", []):
                flow_log_store.append(f)
                print("[FLOW-ONOS]", f)
                producer.send("flow_logs", f)
        else:
            print(f"[ONOS] Flow read error: {response.status_code}")

schedule.every(30).seconds.do(log_flows)

def start_scheduler():
    while True:
        schedule.run_pending()
        time.sleep(1)

def start_flask_api():
    app.run(host="0.0.0.0", port=5005)

if __name__ == "__main__":
    threading.Thread(target=process_alerts, daemon=True).start()
    threading.Thread(target=start_scheduler, daemon=True).start()
    threading.Thread(target=start_flask_api, daemon=True).start()
    while True:
        time.sleep(60)