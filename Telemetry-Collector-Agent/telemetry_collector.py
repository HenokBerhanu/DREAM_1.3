#!/usr/bin/env python3
"""
Telemetry Collector for the Smart-Hospital Edge Node.

 * Subscribes to MQTT topics on the local Mosquitto broker.
 * Publishes raw telemetry to Kafka (`telemetry-raw` topic).
 * Publishes alerts (if any) to Kafka (`telemetry-alerts` topic).

The container is **configuration-free**: every tunable value comes
from environment variables so the same image works in dev & prod.
"""
import json
import os
import ssl
import signal
import sys
import time
from typing import Any, Dict

import paho.mqtt.client as mqtt
from kafka import KafkaProducer
from kafka.errors import KafkaError

# --------------------------------------------------------------------------- #
#  Environment Defaults
# --------------------------------------------------------------------------- #
MQTT_HOST      = os.getenv("MQTT_BROKER_HOST", "127.0.0.1")
MQTT_PORT      = int(os.getenv("MQTT_BROKER_PORT", "1883"))
MQTT_TOPIC     = os.getenv("MQTT_TOPIC",       "devices/#")

KAFKA_BOOTSTRAP  = os.getenv("KAFKA_BOOTSTRAP", "kafka-cluster-kafka-bootstrap.kafka:9093")
TOPIC_RAW        = os.getenv("TOPIC_RAW",       "telemetry-raw")
TOPIC_ALERTS     = os.getenv("TOPIC_ALERTS",    "telemetry-alerts")

# TLS files mounted from the Strimzi Secret (leave empty for PLAINTEXT)
SSL_CA          = os.getenv("KAFKA_SSL_CALOCATION")      # /etc/kafka-certs/ca.crt
SSL_CERT        = os.getenv("KAFKA_SSL_CERTLOCATION")     # /etc/kafka-certs/user.crt
SSL_KEY         = os.getenv("KAFKA_SSL_KEYLOCATION")      # /etc/kafka-certs/user.key
SSL_KEY_PASS    = os.getenv("KAFKA_SSL_KEY_PASSWORD")     # file may be password-protected


def _build_kafka_producer() -> KafkaProducer:
    """Create a KafkaProducer with or without TLS."""
    kwargs: Dict[str, Any] = dict(
        bootstrap_servers=KAFKA_BOOTSTRAP,
        value_serializer=lambda v: json.dumps(v).encode("utf-8"),
        retries=3,
        linger_ms=10,
        acks="all",
    )

    if SSL_CA:
        # -------- TLS mode --------
        ctx = ssl.create_default_context(cafile=SSL_CA)
        ctx.load_cert_chain(certfile=SSL_CERT, keyfile=SSL_KEY, password=SSL_KEY_PASS)
        ctx.check_hostname = False
        ctx.minimum_version = ssl.TLSVersion.TLSv1_2
        kwargs.update(security_protocol="SSL", ssl_context=ctx)

    return KafkaProducer(**kwargs)


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

    # 1) forward to Kafka (raw topic)
    future = producer.send(TOPIC_RAW, payload)
    future.add_errback(lambda exc: print(f"[Kafka] send failed: {exc}", flush=True))

    # 2) (optional) simple built-in anomaly check → alerts topic
    if payload.get("status") == "alert":
        producer.send(TOPIC_ALERTS, payload)

    print(f"[OK] {msg.topic} → Kafka", flush=True)


def on_disconnect(client: mqtt.Client, userdata, rc):
    print("[MQTT] Disconnected, rc =", rc, flush=True)


# --------------------------------------------------------------------------- #
#  Graceful Shutdown
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
    while True:
        try:
            main()
        except Exception as e:
            print(f"[ERROR] Fatal exception: {e}", flush=True)
            time.sleep(5)            # simple back-off before restart
