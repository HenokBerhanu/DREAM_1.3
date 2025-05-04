#!/usr/bin/env python3
import os
import time
import json
import random
import paho.mqtt.client as mqtt

# ── 1) Map logical device IDs → MAC addresses ────────────────────
MAC_MAP = {
    "infusion_pump_01": "00:11:22:33:44:21",
    "infusion_pump_02": "00:11:22:33:44:22",
    "infusion_pump_03": "00:11:22:33:44:23",
}

# ── 2) Broker settings (from env, or defaults) ────────────────────
BROKER = os.getenv("MQTT_BROKER_HOST", "127.0.0.1")
PORT   = int(os.getenv("MQTT_BROKER_PORT", "1883"))
TOPIC  = os.getenv("MQTT_TOPIC", "devices/infusion_pump")

# ── 3) Create client and retry until the broker is ready ───────────
client = mqtt.Client()
while True:
    try:
        client.connect(BROKER, PORT, keepalive=60)
        print(f"[MQTT] Connected to {BROKER}:{PORT}")
        break
    except Exception as e:
        print(f"[MQTT] Connection to {BROKER}:{PORT} failed: {e!r}, retrying in 5s…")
        time.sleep(5)

# ── 4) Kick off the network loop ───────────────────────────────────
client.loop_start()

# ── 5) Publish loop ────────────────────────────────────────────────
device_ids = list(MAC_MAP.keys())
while True:
    for device_id in device_ids:
        flow_rate = round(random.uniform(20.0, 100.0), 2)  # mL/hr
        # build six-element sensor_readings vector
        readings = [flow_rate, 0, 0, 0, 0, 0]

        payload = {
            "device_id":       device_id,
            "device_mac":      MAC_MAP[device_id],
            "timestamp":       int(time.time()),
            "sensor_readings": readings,
            "status":          random.choice(["running", "paused", "completed"])
        }

        client.publish(TOPIC, json.dumps(payload), qos=1)
        print(f"[Infusion Pump] {TOPIC}: {payload}")
        time.sleep(2)   # per-device pacing

    time.sleep(5)       # batch pause





# import paho.mqtt.client as mqtt
# import time, json, random

# client = mqtt.Client()
# client.connect("localhost", 1883, 60)

# device_ids = ["infusion_pump_01", "infusion_pump_02", "infusion_pump_03"]

# while True:
#     for device_id in device_ids:
#         payload = {
#             "device_id": device_id,
#             "timestamp": int(time.time()),
#             "flow_rate": round(random.uniform(20.0, 100.0), 2),  # mL/hr
#             "status": random.choice(["running", "paused", "completed"])
#         }
#         client.publish("hospital/infusion_pump", json.dumps(payload))
#         print(f"Sent: {payload}")
#         time.sleep(2)
