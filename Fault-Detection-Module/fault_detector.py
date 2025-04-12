from flask import Flask
from kafka import KafkaConsumer, KafkaProducer
import tensorflow as tf
import numpy as np
import requests
import json
import threading

app = Flask(__name__)
alerts_producer = KafkaProducer(
    bootstrap_servers="kafka-service:9092",
    value_serializer=lambda x: json.dumps(x).encode('utf-8')
)

model = tf.keras.models.load_model("autoencoder_model.h5")

def detect_faults():
    consumer = KafkaConsumer(
        "telemetry_data",
        bootstrap_servers="kafka-service:9092",
        value_deserializer=lambda x: json.loads(x.decode("utf-8"))
    )
    for msg in consumer:
        x = np.array(msg.value["sensor_readings"]).reshape(1, -1)
        x_hat = model.predict(x)
        error = np.mean(np.abs(x - x_hat))
        if error > 0.05:
            alert = {"device_id": msg.value["device_id"], "error": float(error)}
            print("Anomaly detected:", alert)
            alerts_producer.send("anomaly_alerts", alert)

            # Notify ONOS controller
            requests.post("http://onos-service:8181/api/flow/update", json={
                "device_id": msg.value["device_id"],
                "priority": "high"
            }, auth=("onos", "rocks"))

if __name__ == "__main__":
    threading.Thread(target=detect_faults, daemon=True).start()
    app.run(host="0.0.0.0", port=5004)
