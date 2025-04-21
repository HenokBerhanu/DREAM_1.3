import paho.mqtt.client as mqtt
import time, json, random

client = mqtt.Client()
client.connect("localhost", 1883, 60)

device_ids = ["infusion_pump_01", "infusion_pump_02", "infusion_pump_03"]

while True:
    for device_id in device_ids:
        payload = {
            "device_id": device_id,
            "timestamp": int(time.time()),
            "flow_rate": round(random.uniform(20.0, 100.0), 2),  # mL/hr
            "status": random.choice(["running", "paused", "completed"])
        }
        client.publish("hospital/infusion_pump", json.dumps(payload))
        print(f"Sent: {payload}")
        time.sleep(2)
