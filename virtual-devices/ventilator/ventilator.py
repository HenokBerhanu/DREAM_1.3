import paho.mqtt.client as mqtt
import time, json, random

client = mqtt.Client()
client.connect("localhost", 1883, 60)

device_ids = ["ventilator_01", "ventilator_02", "ventilator_03"]

while True:
    for device_id in device_ids:
        payload = {
            "device_id": device_id,
            "timestamp": int(time.time()),
            "respiratory_rate": random.randint(12, 25),  # breaths/min
            "tidal_volume": round(random.uniform(300.0, 500.0), 1),  # mL
            "status": random.choice(["operational", "alert", "standby"])
        }
        client.publish("hospital/ventilator", json.dumps(payload))
        print(f"Sent: {payload}")
        time.sleep(2)
