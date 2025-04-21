import paho.mqtt.client as mqtt
import time, json, random

client = mqtt.Client()
client.connect("localhost", 1883, 60)

device_ids = ["wheelchair_01", "wheelchair_02", "wheelchair_03"]

while True:
    for device_id in device_ids:
        payload = {
            "device_id": device_id,
            "timestamp": int(time.time()),
            "location": {
                "room": random.randint(100, 120),
                "floor": random.randint(1, 5)
            },
            "battery_level": random.randint(20, 100),  # in %
            "status": random.choice(["in-use", "idle", "charging"])
        }
        client.publish("hospital/wheelchair", json.dumps(payload))
        print(f"Sent: {payload}")
        time.sleep(2)
