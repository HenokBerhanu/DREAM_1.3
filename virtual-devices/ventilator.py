import time, json, random
import paho.mqtt.client as mqtt

client = mqtt.Client("Ventilator")
client.connect("mqtt-broker-service", 1883)

while True:
    data = {
        "device_id": "ventilator-01",
        "sensor_readings": [random.uniform(0.2, 0.8), random.uniform(90, 100), random.uniform(12, 20)],
        "timestamp": time.time()
    }
    client.publish("devices/ventilator", json.dumps(data))
    print("[Ventilator] Sent:", data)
    time.sleep(5)