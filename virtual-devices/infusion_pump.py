client = mqtt.Client("InfusionPump")
client.connect("mqtt-broker-service", 1883)

while True:
    data = {
        "device_id": "infusion-pump-01",
        "sensor_readings": [random.uniform(0.5, 1.0), random.uniform(20, 30)],  # Flow rate, battery level
        "timestamp": time.time()
    }
    client.publish("devices/infusion", json.dumps(data))
    print("[Infusion Pump] Sent:", data)
    time.sleep(5)
