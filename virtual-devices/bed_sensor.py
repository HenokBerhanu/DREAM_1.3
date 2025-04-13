client = mqtt.Client("BedSensor")
client.connect("mqtt-broker-service", 1883)

while True:
    data = {
        "device_id": "bed-sensor-01",
        "sensor_readings": [random.choice([0, 1])],  # Occupancy
        "timestamp": time.time()
    }
    client.publish("devices/bed", json.dumps(data))
    print("[Bed Sensor] Sent:", data)
    time.sleep(5)
