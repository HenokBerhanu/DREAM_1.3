#!/usr/bin/env python3
import os
import time
import json
import random
import paho.mqtt.client as mqtt

# ── 1) Map logical device IDs → MAC addresses ────────────────────
MAC_MAP = {
    "bed_sensor_01": "00:11:22:33:44:11",
    "bed_sensor_02": "00:11:22:33:44:12",
    "bed_sensor_03": "00:11:22:33:44:13",
}

# ── 2) Broker settings (from env, or defaults) ────────────────────
BROKER = os.getenv("MQTT_BROKER_HOST", "127.0.0.1")
PORT   = int(os.getenv("MQTT_BROKER_PORT", "1883"))
TOPIC  = os.getenv("MQTT_TOPIC", "devices/bed_sensor")

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
        occupancy = random.choice([0, 1])
        # six-element sensor_readings vector
        readings = [occupancy, 0, 0, 0, 0, 0]

        payload = {
            "device_id":       device_id,
            "device_mac":      MAC_MAP[device_id],
            "timestamp":       int(time.time()),
            "sensor_readings": readings,
            "status":          "occupied" if occupancy else "vacant"
        }

        client.publish(TOPIC, json.dumps(payload), qos=1)
        print(f"[Bed Sensor] {TOPIC}: {payload}")
        time.sleep(2)   # per-device pacing

    time.sleep(5)       # batch pause






# import paho.mqtt.client as mqtt
# import time, json, random

# client = mqtt.Client()
# client.connect("localhost", 1883, 60)

# while True:
#     payload = {
#         "device_id": "bed_sensor_01",
#         "timestamp": int(time.time()),
#         "occupancy": random.choice([0, 1])
#     }
#     client.publish("hospital/bed_sensor", json.dumps(payload))
#     print(f"Sent: {payload}")
#     time.sleep(5)

# import paho.mqtt.client as mqtt
# import time, json, random

# client = mqtt.Client()
# client.connect("localhost", 1883, 60)

# bed_ids = ["bed_sensor_01", "bed_sensor_02", "bed_sensor_03"]

# while True:
#     for bed_id in bed_ids:
#         payload = {
#             "device_id": bed_id,
#             "timestamp": int(time.time()),
#             "occupancy": random.choice([0, 1])
#         }
#         client.publish("hospital/bed_sensor", json.dumps(payload))
#         print(f"Sent: {payload}")
#         time.sleep(1)  # short delay between each sensor to mimic staggered updates

#     time.sleep(5)  # wait before next round
