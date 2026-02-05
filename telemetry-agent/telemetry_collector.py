#!/usr/bin/env python3
import json
import os
import ssl
import signal
import sys
import time
from typing import Any, Dict

import paho.mqtt.client as mqtt
from kafka import KafkaProducer, errors as kafka_errors
from prometheus_client import start_http_server, Counter

# --------------------------------------------------------------------------- #
#  Prometheus metrics
# --------------------------------------------------------------------------- #
telemetry_forwarded = Counter(
    "telemetry_messages_forwarded_total",
    "Total telemetry messages forwarded to Kafka"
)
alerts_detected = Counter(
    "alerts_detected_total",
    "Total alert messages forwarded to Kafka"
)

# --------------------------------------------------------------------------- #
#  Environment Variables
# --------------------------------------------------------------------------- #
MQTT_HOST      = os.getenv("MQTT_BROKER_HOST", "127.0.0.1")
MQTT_PORT      = int(os.getenv("MQTT_BROKER_PORT", "1883"))
MQTT_TOPIC     = os.getenv("MQTT_TOPIC", "devices/#")

KAFKA_BOOTSTRAP = os.getenv("KAFKA_BOOTSTRAP", "localhost:9092")
TOPIC_RAW       = os.getenv("TOPIC_RAW", "telemetry-raw")
TOPIC_ALERTS    = os.getenv("TOPIC_ALERTS", "telemetry-alerts")

SSL_CA       = os.getenv("KAFKA_SSL_CALOCATION")
SSL_CERT     = os.getenv("KAFKA_SSL_CERTLOCATION")
SSL_KEY      = os.getenv("KAFKA_SSL_KEYLOCATION")
SSL_KEY_PASS = os.getenv("KAFKA_SSL_KEY_PASSWORD")

# --------------------------------------------------------------------------- #
#  Kafka producer creation with retries
# --------------------------------------------------------------------------- #
def _build_kafka_producer() -> KafkaProducer:
    """Create a KafkaProducer with or without TLS and retry if needed."""
    kwargs: Dict[str, Any] = dict(
        bootstrap_servers=KAFKA_BOOTSTRAP,
        value_serializer=lambda v: json.dumps(v).encode("utf-8"),
        retries=3,
        linger_ms=10,
        acks="all",
    )

    if SSL_CA:
        try:
            ctx = ssl.create_default_context(cafile=SSL_CA)
            ctx.load_cert_chain(certfile=SSL_CERT, keyfile=SSL_KEY, password=SSL_KEY_PASS)
            ctx.check_hostname = False
            ctx.minimum_version = ssl.TLSVersion.TLSv1_2
            kwargs.update(security_protocol="SSL", ssl_context=ctx)
            print("[KAFKA] SSL/TLS context loaded successfully.")
        except Exception as e:
            print(f"[ERROR] Failed to setup SSL context: {e}", flush=True)
            sys.exit(1)

    # Retry connection
    retries = 0
    while retries < 5:
        try:
            producer = KafkaProducer(**kwargs)
            print("[KAFKA] Producer connected successfully.")
            return producer
        except kafka_errors.NoBrokersAvailable as e:
            print(f"[WARN] Kafka broker not available, retrying in 5s ({retries+1}/5)...: {e}", flush=True)
            retries += 1
            time.sleep(5)

    print("[ERROR] Could not connect to Kafka after retries.")
    sys.exit(1)

# Create the producer
producer: KafkaProducer = _build_kafka_producer()

# --------------------------------------------------------------------------- #
#  MQTT callbacks
# --------------------------------------------------------------------------- #
def on_connect(client: mqtt.Client, userdata, flags, rc):
    print(f"[MQTT] Connected with result code {rc} — subscribing to {MQTT_TOPIC}")
    client.subscribe(MQTT_TOPIC, qos=1)

def on_message(client: mqtt.Client, userdata, msg: mqtt.MQTTMessage):
    try:
        payload = json.loads(msg.payload.decode())
    except json.JSONDecodeError:
        print(f"[WARN] Non-JSON payload on {msg.topic}: {msg.payload[:40]}…", flush=True)
        return

    # 1) Forward to Kafka (raw topic)
    future = producer.send(TOPIC_RAW, payload)
    future.add_errback(lambda exc: print(f"[Kafka] Send failed: {exc}", flush=True))
    telemetry_forwarded.inc()

    # 2) (optional) simple built-in anomaly check → alerts topic
    if payload.get("status") == "alert":
        producer.send(TOPIC_ALERTS, payload)
        alerts_detected.inc()

    print(f"[OK] {msg.topic} → Kafka", flush=True)

def on_disconnect(client: mqtt.Client, userdata, rc):
    print("[MQTT] Disconnected, rc =", rc, flush=True)

# --------------------------------------------------------------------------- #
#  Graceful shutdown
# --------------------------------------------------------------------------- #
def shutdown(signum, frame):
    print("\nShutting down gracefully…", flush=True)
    producer.flush(5)
    producer.close(5)
    sys.exit(0)

for s in (signal.SIGINT, signal.SIGTERM):
    signal.signal(s, shutdown)

# --------------------------------------------------------------------------- #
#  Main
# --------------------------------------------------------------------------- #
def main():
    print(f"Starting Telemetry-Collector — MQTT {MQTT_HOST}:{MQTT_PORT}  ⇒  Kafka {KAFKA_BOOTSTRAP}")
    mqtt_client = mqtt.Client()
    mqtt_client.on_connect = on_connect
    mqtt_client.on_message = on_message
    mqtt_client.on_disconnect = on_disconnect

    mqtt_client.connect(MQTT_HOST, MQTT_PORT, keepalive=60)
    mqtt_client.loop_forever()

if __name__ == "__main__":
    start_http_server(8080)  # Expose Prometheus metrics
    while True:
        try:
            main()
        except Exception as e:
            print(f"[ERROR] Fatal exception: {e}", flush=True)
            time.sleep(5)  # simple back-off before restart
