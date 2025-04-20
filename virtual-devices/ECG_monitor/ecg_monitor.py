import paho.mqtt.client as mqtt
import time, json, random

client = mqtt.Client()
client.connect("localhost", 1883, 60)

device_ids = ["ecg_monitor_01", "ecg_monitor_02", "ecg_monitor_03"]

while True:
    for device_id in device_ids:
        payload = {
            "device_id": device_id,
            "timestamp": int(time.time()),
            "heart_rate": random.randint(60, 100),
            "rhythm": random.choice(["Normal", "Arrhythmia"])
        }
        client.publish("hospital/ecg_monitor", json.dumps(payload))
        print(f"Sent: {payload}")
        time.sleep(2)
