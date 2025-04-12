from flask import Flask, request, jsonify
import numpy as np
import tensorflow as tf
from kafka import KafkaConsumer
import json

app = Flask(__name__)

# Load pre-trained autoencoder model
model = tf.keras.models.load_model("autoencoder_model.h5")

# Kafka consumer to receive telemetry data
consumer = KafkaConsumer(
    "telemetry_data",
    bootstrap_servers="kafka-service:9092",
    value_deserializer=lambda x: json.loads(x.decode("utf-8"))
)

@app.route("/predict", methods=["POST"])
def predict():
    data = request.get_json()
    input_data = np.array(data["sensor_readings"]).reshape(1, -1)
    
    # Predict reconstruction error
    reconstructed = model.predict(input_data)
    error = np.mean(np.abs(input_data - reconstructed))

    if error > 0.05:  # Set anomaly threshold
        return jsonify({"status": "anomaly", "error_score": error})
    else:
        return jsonify({"status": "normal", "error_score": error})

# Stream data from Kafka and analyze
def consume_kafka():
    for message in consumer:
        sensor_data = message.value["sensor_readings"]
        reconstructed = model.predict([sensor_data])
        error = np.mean(np.abs(sensor_data - reconstructed))
        if error > 0.05:
            print(f"Anomaly detected: {error}")
            # Notify SDN controller via REST API (TBD)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001)
