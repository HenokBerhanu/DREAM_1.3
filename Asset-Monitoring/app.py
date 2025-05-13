from flask import Flask, render_template, jsonify
from prometheus_client import Counter, generate_latest, CONTENT_TYPE_LATEST
from kafka import KafkaConsumer
import os, threading, json, time

app = Flask(__name__, template_folder="/app/templates")

KAFKA_BOOTSTRAP = os.getenv("KAFKA_BOOTSTRAP", "kafka-cluster-kafka-bootstrap.microservices.svc.cluster.local:9092")
ALERT_TOPIC = os.getenv("ALERT_TOPIC", "anomaly_alerts")
SEC_AGENT_URL = os.getenv("SEC_AGENT_URL", "http://security-enforcement-agent.edge-agents.svc.cluster.local:5005/api/flows")

alerts, flows = [], []
alert_counter = Counter("dashboard_alert_total", "Total alerts received from Kafka")


def consume_kafka():
    # retry loop – the pod will start even if the broker comes up later
    while True:
        try:
            consumer = KafkaConsumer(
                ALERT_TOPIC,
                bootstrap_servers=KAFKA_BOOTSTRAP,
                value_deserializer=lambda x: json.loads(x.decode()),
                group_id="asset-dashboard")
            for msg in consumer:
                alerts.append(msg.value)
                alert_counter.inc()
                if len(alerts) > 100:
                    alerts.pop(0)
        except Exception as e:
            app.logger.warning("Kafka not available yet – %s", e)
            time.sleep(5)

threading.Thread(target=consume_kafka, daemon=True).start()

@app.route("/")
def index():
    return render_template("index.html", sec_agent_url=SEC_AGENT_URL)

@app.route("/api/alerts")
def get_alerts():
    return jsonify(alerts)

@app.route("/metrics")
def metrics():
    return generate_latest(), 200, {"Content-Type": CONTENT_TYPE_LATEST}

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5003, threaded=True)