client = mqtt.Client("ECG")
client.connect("mqtt-broker-service", 1883)

while True:
    data = {
        "device_id": "ecg-01",
        "sensor_readings": [random.uniform(60, 100), random.uniform(0.9, 1.1)],  # BPM and signal range
        "timestamp": time.time()
    }
    client.publish("devices/ecg", json.dumps(data))
    print("[ECG] Sent:", data)
    time.sleep(5)
