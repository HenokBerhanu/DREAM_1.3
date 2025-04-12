import time
import json
import random
import paho.mqtt.client as mqtt

broker = "mqtt-broker-service"
port = 1883
topic = "devices/ventilator"

client = mqtt.Client("VentilatorSimulator")
client.connect(broker, port)

while True:
    telemetry = {
        "device_id": "ventilator-01",
        "sensor_readings": [
            random.uniform(0.2, 0.8),  # Pressure
            random.uniform(90, 100),  # Oxygen saturation
            random.uniform(12, 20)    # Respiratory rate
        ],
        "timestamp": time.time()
    }
    client.publish(topic, json.dumps(telemetry))
    print("Published:", telemetry)
    time.sleep(5)