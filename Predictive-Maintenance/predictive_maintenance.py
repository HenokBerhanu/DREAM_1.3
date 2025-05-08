#!/usr/bin/env python3
"""
Predictive Maintenance Module for Smart Healthcare SDN
- Subscribes to raw telemetry from Kafka
- Runs Autoencoder model to detect anomalies
- Exposes health (`/healthz`) and metrics (`/metrics`) endpoints via Flask
- Publishes anomaly alerts to Kafka and notifies SDN controller via REST
"""
import os
import json
import threading
import time
import requests
import numpy as np
import tensorflow as tf
from flask import Flask, request, jsonify, Response
from kafka import KafkaConsumer, KafkaProducer, errors as kafka_errors
from prometheus_client import Counter, generate_latest, CONTENT_TYPE_LATEST

# ---- Configuration via Environment ----
KAFKA_BOOTSTRAP   = os.getenv("KAFKA_BOOTSTRAP", "kafka-cluster-kafka-bootstrap.kafka:9092")
INPUT_TOPIC       = os.getenv("INPUT_TOPIC", "telemetry-raw")
ALERT_TOPIC       = os.getenv("ALERT_TOPIC", "maintenance-alerts")
ONOS_URL          = os.getenv("ONOS_URL", "http://onos-service.micro-onos.svc.cluster.local:8181/onos/v1")
ONOS_AUTH_USER    = os.getenv("ONOS_AUTH_USER", "onos")
ONOS_AUTH_PASS    = os.getenv("ONOS_AUTH_PASS", "rocks")
MODEL_PATH        = os.getenv("MODEL_PATH", "/models/autoencoder_model.h5")
ERROR_THRESHOLD   = float(os.getenv("ERROR_THRESHOLD", "0.05"))
HTTP_PORT         = int(os.getenv("HTTP_PORT", "5001"))
SWITCH_ID         = os.getenv("SWITCH_ID", "of:0000000000000001")

# ---- Prometheus Metrics ----
telemetry_processed = Counter(
    'maintenance_telemetry_processed_total',
    'Total number of telemetry messages processed'
)
anomalies_detected = Counter(
    'maintenance_anomalies_detected_total',
    'Total number of anomalies detected'
)

# ---- Flask App ----
app = Flask(__name__)

@app.route("/healthz")
def healthz():
    return jsonify(status="ok"), 200

@app.route("/metrics")
def metrics():
    data = generate_latest()
    return Response(data, mimetype=CONTENT_TYPE_LATEST)

@app.route("/predict", methods=["POST"])
def predict():
    payload = request.get_json(force=True)
    readings = payload.get('sensor_readings')
    if not isinstance(readings, (list, tuple)):
        return jsonify(error="Invalid sensor_readings"), 400

    x = np.array(readings).reshape(1, -1)
    reconstructed = model.predict(x)
    error = float(np.mean(np.abs(x - reconstructed)))
    status = 'anomaly' if error > ERROR_THRESHOLD else 'normal'
    return jsonify(status=status, error_score=error)

# ---- Kafka Producer/Consumer ----
def build_producer():
    retries = 0
    while retries < 5:
        try:
            p = KafkaProducer(
                bootstrap_servers=KAFKA_BOOTSTRAP,
                value_serializer=lambda v: json.dumps(v).encode('utf-8')
            )
            print(f"[Kafka] Producer connected to {KAFKA_BOOTSTRAP}")
            return p
        except kafka_errors.NoBrokersAvailable:
            retries += 1
            time.sleep(5)
    raise RuntimeError("Failed to connect Kafka producer")

producer = build_producer()

# Load model
print(f"[Model] Loading autoencoder from {MODEL_PATH}")
model = tf.keras.models.load_model(MODEL_PATH, compile=False)

# ---- Background Consumer Loop ----
def consume_and_predict():
    consumer = KafkaConsumer(
        INPUT_TOPIC,
        bootstrap_servers=KAFKA_BOOTSTRAP,
        value_deserializer=lambda b: json.loads(b.decode('utf-8')),
        auto_offset_reset='latest',
        group_id='maintenance-group'
    )
    print(f"[Kafka] Subscribed to topic {INPUT_TOPIC}")

    for msg in consumer:
        telemetry_processed.inc()
        data = msg.value
        readings = data.get('sensor_readings')
        if not isinstance(readings, (list, tuple)):
            continue

        x = np.array(readings).reshape(1, -1)
        reconstructed = model.predict(x)
        error = float(np.mean(np.abs(x - reconstructed)))
        if error <= ERROR_THRESHOLD:
            continue

        anomalies_detected.inc()
        device_id = data.get('device_id')
        alert = {"device_id": device_id, "error": error}
        print("[Alert] Predictive anomaly detected:", alert)

        # publish alert to Kafka
        producer.send(ALERT_TOPIC, alert)
        producer.flush()

        # notify SDN controller
        flow = {
            "priority": 40000,
            "isPermanent": True,
            "deviceId": SWITCH_ID,
            "treatment": {"instructions": [{"type": "OUTPUT", "port": "CONTROLLER"}]},
            "selector": {"criteria": [{"type": "ETH_SRC", "mac": data.get('device_mac')} ]}
        }
        try:
            resp = requests.post(
                f"{ONOS_URL}/flows/{SWITCH_ID}",
                auth=(ONOS_AUTH_USER, ONOS_AUTH_PASS),
                json=flow,
                timeout=5
            )
            print(f"[ONOS] Flow update responded: {resp.status_code}")
        except Exception as e:
            print(f"[ONOS] Error: {e}")

if __name__ == '__main__':
    threading.Thread(target=consume_and_predict, daemon=True).start()
    app.run(host='0.0.0.0', port=HTTP_PORT)