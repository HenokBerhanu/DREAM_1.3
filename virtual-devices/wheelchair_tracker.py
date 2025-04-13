client = mqtt.Client("Wheelchair")
client.connect("mqtt-broker-service", 1883)

while True:
    data = {
        "device_id": "wheelchair-01",
        "sensor_readings": [random.uniform(0, 1), random.uniform(0, 1)],  # X/Y location
        "timestamp": time.time()
    }
    client.publish("devices/wheelchair", json.dumps(data))
    print("[Wheelchair] Sent:", data)
    time.sleep(5)
