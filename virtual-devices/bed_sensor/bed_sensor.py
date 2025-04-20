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

import paho.mqtt.client as mqtt
import time, json, random

client = mqtt.Client()
client.connect("localhost", 1883, 60)

bed_ids = ["bed_sensor_01", "bed_sensor_02", "bed_sensor_03"]

while True:
    for bed_id in bed_ids:
        payload = {
            "device_id": bed_id,
            "timestamp": int(time.time()),
            "occupancy": random.choice([0, 1])
        }
        client.publish("hospital/bed_sensor", json.dumps(payload))
        print(f"Sent: {payload}")
        time.sleep(1)  # short delay between each sensor to mimic staggered updates

    time.sleep(5)  # wait before next round
