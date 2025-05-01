#!/usr/bin/env python3
"""
Fault Detection Module for Smart Healthcare SDN Core Network
- Subscribes to raw telemetry from Kafka
- Runs Autoencoder model to detect anomalies
- Publishes anomaly alerts to Kafka
- Notifies ONOS controller via REST
- Exposes health (`/healthz`) and Prometheus metrics (`/metrics`) via Flask
"""
import os
import json
import threading
import time
import requests
import numpy as np
import tensorflow as tf
from flask import Flask, jsonify, Response
from kafka import KafkaConsumer, KafkaProducer, errors as kafka_errors
from prometheus_client import Counter, generate_latest, CONTENT_TYPE_LATEST

# -------------------- Configuration via Environment --------------------
KAFKA_BOOTSTRAP   = os.getenv("KAFKA_BOOTSTRAP", "kafka-cluster-kafka-bootstrap.kafka:9092")
TELEMETRY_TOPIC   = os.getenv("TELEMETRY_TOPIC", "telemetry-raw")
ALERT_TOPIC       = os.getenv("ALERT_TOPIC", "telemetry-alerts")
ONOS_URL          = os.getenv("ONOS_URL", "http://onos-service:8181/onos/v1")
ONOS_AUTH_USER    = os.getenv("ONOS_AUTH_USER", "onos")
ONOS_AUTH_PASS    = os.getenv("ONOS_AUTH_PASS", "rocks")
MODEL_PATH        = os.getenv("MODEL_PATH", "/models/autoencoder_model.h5")
ERROR_THRESHOLD   = float(os.getenv("ERROR_THRESHOLD", "0.05"))
HTTP_PORT         = int(os.getenv("HTTP_PORT", "5004"))

# ----------------------- Prometheus Metrics -----------------------------
telemetry_processed = Counter(
    'fault_detector_telemetry_processed_total',
    'Total number of telemetry messages processed'
)
anomalies_detected = Counter(
    'fault_detector_anomalies_detected_total',
    'Total number of anomalies detected'
)

# ----------------------- Flask App ---------------------------------------
app = Flask(__name__)

@app.route("/healthz")
def healthz():
    return jsonify(status="ok"), 200

@app.route("/metrics")
def metrics():
    # Expose Prometheus metrics
    data = generate_latest()
    return Response(data, mimetype=CONTENT_TYPE_LATEST)

# ----------------------- Kafka Producer Setup ---------------------------

def build_producer():
    retries = 0
    while retries < 5:
        try:
            producer = KafkaProducer(
                bootstrap_servers=KAFKA_BOOTSTRAP,
                value_serializer=lambda v: json.dumps(v).encode('utf-8'),
            )
            print(f"[Kafka] Producer connected to {KAFKA_BOOTSTRAP}")
            return producer
        except kafka_errors.NoBrokersAvailable as e:
            print(f"[Kafka] Producer connection failed ({retries+1}/5): {e}")
            retries += 1
            time.sleep(5)
    print("[Kafka] Producer failed after retries.")
    exit(1)

producer = build_producer()

# ----------------------- Load ML Model ----------------------------------
print(f"[Model] Loading autoencoder from {MODEL_PATH} (inference only)")
# compile=False to skip loss compilation
model = tf.keras.models.load_model(MODEL_PATH, compile=False)

# ----------------------- Fault Detection Loop ---------------------------

def detect_faults():
    retries = 0
    while retries < 5:
        try:
            consumer = KafkaConsumer(
                TELEMETRY_TOPIC,
                bootstrap_servers=KAFKA_BOOTSTRAP,
                value_deserializer=lambda m: json.loads(m.decode('utf-8')),
                auto_offset_reset='earliest',
                enable_auto_commit=True,
                group_id='fault-detector-group'
            )
            print(f"[Kafka] Subscribed to {TELEMETRY_TOPIC}")
            break
        except kafka_errors.NoBrokersAvailable as e:
            print(f"[Kafka] Consumer connect failed ({retries+1}/5): {e}")
            retries += 1
            time.sleep(5)
    else:
        print("[Kafka] Consumer failed after retries.")
        exit(1)

    for msg in consumer:
        # Count every telemetry message
        telemetry_processed.inc()
        data = msg.value
        readings = data.get('sensor_readings')
        if readings is None:
            print("[Warning] Missing 'sensor_readings' in message", data)
            continue

        # Prepare input for autoencoder
        x = np.array(readings).reshape(1, -1)
        x_hat = model.predict(x)
        error = float(np.mean(np.abs(x - x_hat)))
        print(f"[FaultDetector] Reconstruction error = {error:.6f}")

        if error > ERROR_THRESHOLD:
            anomalies_detected.inc()
            alert = {"device_id": data.get('device_id'), "error": error}
            print("[Alert] Anomaly detected:", alert)

            # Publish to Kafka
            producer.send(ALERT_TOPIC, alert)
            producer.flush()

            # Notify ONOS via REST
            try:
                resp = requests.post(
                    f"{ONOS_URL}/flows/{data.get('device_id')}",
                    auth=(ONOS_AUTH_USER, ONOS_AUTH_PASS),
                    json={"priority": "high"},
                    timeout=5
                )
                print(f"[ONOS] Flow update responded: {resp.status_code}")
            except requests.RequestException as e:
                print(f"[ONOS] REST error: {e}")

if __name__ == '__main__':
    # Start detection in background
    threading.Thread(target=detect_faults, daemon=True).start()
    # Run Flask HTTP server for health & metrics
    app.run(host='0.0.0.0', port=HTTP_PORT)