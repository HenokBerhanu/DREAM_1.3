import paho.mqtt.client as mqtt
from kafka import KafkaProducer
import json

producer = KafkaProducer(
    bootstrap_servers="kafka-service:9092",
    value_serializer=lambda x: json.dumps(x).encode("utf-8")
)

def on_message(client, userdata, msg):
    payload = json.loads(msg.payload.decode())
    print(f"Received from MQTT: {payload}")
    producer.send("telemetry_data", payload)

client = mqtt.Client()
client.connect("mqtt-broker-service", 1883)
client.subscribe("devices/#")
client.on_message = on_message
client.loop_forever()