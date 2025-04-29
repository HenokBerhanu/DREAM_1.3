#!/usr/bin/env python3
import time
import json
import random
import paho.mqtt.publish as mqtt_publish 

BROKER = "127.0.0.1"
PORT = 1883

def publish(topic, payload, label):
    msg = json.dumps(payload)
    print(f"[{label}] {topic}: {msg}")
    mqtt_publish.single(topic, msg, hostname=BROKER, port=PORT)

def test_bed_sensor():
    payload = {
        "device_id": "bed_sensor_01",
        "timestamp": int(time.time()),
        "occupancy": random.choice([0, 1])
    }
    publish("hospital/bed_sensor", payload, "Bed Sensor")

def test_ecg_monitor():
    payload = {
        "device_id": "ecg_monitor_01",
        "timestamp": int(time.time()),
        "heart_rate": random.randint(60, 100),
        "rhythm": "Normal"
    }
    publish("hospital/ecg_monitor", payload, "ECG Monitor")

def test_infusion_pump():
    payload = {
        "device_id": "infusion_pump_01",
        "timestamp": int(time.time()),
        "flow_rate": round(random.uniform(20.0, 100.0), 2),
        "status": "running"
    }
    publish("hospital/infusion_pump", payload, "Infusion Pump")

def test_ventilator():
    payload = {
        "device_id": "ventilator_01",
        "timestamp": int(time.time()),
        "respiratory_rate": random.randint(12, 25),
        "tidal_volume": round(random.uniform(300.0, 500.0), 1),
        "status": "operational"
    }
    publish("hospital/ventilator", payload, "Ventilator")

def test_wheelchair():
    payload = {
        "device_id": "wheelchair_01",
        "timestamp": int(time.time()),
        "location": {
            "room": random.randint(100, 120),
            "floor": random.randint(1, 5)
        },
        "battery_level": random.randint(20, 100),
        "status": "in-use"
    }
    publish("hospital/wheelchair", payload, "Wheelchair")

def test_alert():
    payload = {
        "device_id": "ventilator_01",
        "timestamp": int(time.time()),
        "status": "alert"
    }
    publish("hospital/ventilator", payload, "ALERT (ventilator)")

if __name__ == "__main__":
    print("Sending test messages...\n")
    test_bed_sensor()
    time.sleep(1)
    test_ecg_monitor()
    time.sleep(1)
    test_infusion_pump()
    time.sleep(1)
    test_ventilator()
    time.sleep(1)
    test_wheelchair()
    time.sleep(1)
    test_alert()
    print("\nDone.")


