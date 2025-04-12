from flask import Flask, render_template, jsonify
from kafka import KafkaConsumer
import threading
import json

app = Flask(__name__)
alerts = []

def consume_kafka():
    consumer = KafkaConsumer(
        "anomaly_alerts",
        bootstrap_servers="kafka-service:9092",
        value_deserializer=lambda x: json.loads(x.decode("utf-8"))
    )
    for msg in consumer:
        alerts.append(msg.value)
        if len(alerts) > 50:
            alerts.pop(0)

@app.route("/")
def index():
    return render_template("index.html")

@app.route("/api/alerts")
def get_alerts():
    return jsonify(alerts)

if __name__ == "__main__":
    threading.Thread(target=consume_kafka, daemon=True).start()
    app.run(host="0.0.0.0", port=5003)
