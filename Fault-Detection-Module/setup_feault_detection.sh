# cd Fault-Detection-Module/
# docker build -t henok/fault-detector:v8 .
# docker tag henok/fault-detector:v8 henok28/fault-detector:v8
# docker push henok28/fault-detector:v8

vagrant ssh-config MasterNode

# coppy from the host to the master node
sudo scp -i /home/henok/DREAM_1.3/Kubernetes-deplyment/.vagrant/machines/MasterNode/virtualbox/private_key \
-P 2222 \
~/DREAM_1.3/Fault-Detection-Module/fault_detector_deployment.yaml \
vagrant@127.0.0.1:/home/vagrant/

# Train and generate autoencoder model in the host machin
pip install tensorflow numpy
python build_autoencoder.py

# coppy the model to the master node
sudo scp -i /home/henok/DREAM_1.3/Kubernetes-deplyment/.vagrant/machines/MasterNode/virtualbox/private_key \
-P 2222 \
~/DREAM_1.3/Fault-Detection-Module/autoencoder_model.h5 \
vagrant@127.0.0.1:/home/vagrant/

# create microservices ns
kubectl create ns microservices

# Create the ConfigMap for your trained model
kubectl -n microservices create configmap fault-detector-model \
  --from-file=autoencoder_model.h5=/home/vagrant/autoencoder_model.h5 \
  --dry-run=client -o yaml | kubectl apply -f -

# Apply the Deployment & Service
kubectl apply -f fault_detector_deployment.yaml

# Verify the rollout
kubectl -n microservices rollout status deploy/fault-detector
kubectl -n microservices rollout restart deployment/fault-detector
kubectl -n microservices get pods -l app=fault-detector -o wide

# change the onos listening url in the deplyment yaml
kubectl -n microservices set env deployment/fault-detector \
  ONOS_URL=http://onos-controller.micro-onos.svc.cluster.local:8181/onos/v1
kubectl -n microservices rollout restart deployment/fault-detector


#######################################################################
# Smoke-test the HTTP endpoints
# port-forward to the local machine
kubectl -n microservices port-forward svc/fault-detector 5004:5004

# In another terminal:
curl http://127.0.0.1:5004/healthz   # should return {"status":"ok"}
curl http://127.0.0.1:5004/metrics   # shows Prometheus metrics endpoint

# Prometheus scrape:
# If the number is rising, it’s processing Kafka messages.
kubectl -n microservices port-forward svc/fault-detector 5004:5004 &
curl http://127.0.0.1:5004/metrics | grep fault_detector_telemetry_processed_total


# Check Kafka topics
# If you feed in some “bad” telemetry (e.g. via your test MQTT scripts), you should see JSON alerts appear.
kubectl -n kafka exec -it kafka-cluster-kafka-0 -- \
  bin/kafka-console-consumer.sh \
    --bootstrap-server localhost:9092 \
    --topic telemetry-alerts \
    --from-beginning

# Inspect the consumer group in Kafka
# Since we’ve set the consumer to use group_id='fault-detector-group', we can ask Kafka for its offset and lag:
kubectl -n kafka exec -it kafka-cluster-kafka-0 -- \
  bin/kafka-consumer-groups.sh \
    --bootstrap-server localhost:9092 \
    --describe \
    --group fault-detector-group

    # output
    TOPIC            PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG            CONSUMER-ID
    telemetry-raw    0          1234            1234            0              fault-detector-...
########################################################################################################################

#################################################
# check the pretrained autoencoder model is working
# Check the model presence
kubectl -n microservices exec -it fault-detector-56766d7bdf-rtv2j -- ls /models

# check the python script inside the container
kubectl -n microservices exec -it fault-detector-56766d7bdf-rtv2j -- /bin/sh

# python3
>>> import numpy as np, tensorflow as tf
>>> model = tf.keras.models.load_model('/models/autoencoder_model.h5', compile=False)
>>> print("✅  Model loaded. Input shape:", model.input_shape)
>>> sample = np.zeros((1,) + model.input_shape[1:])
>>> out = model.predict(sample)
>>> print("Output shape:", out.shape)
>>> exit()

# This confirms that,
The ConfigMap-mounted /models/autoencoder_model.h5 is present.
TensorFlow can load the HDF5 file (with compile=False so you avoid the mse lookup error).
A zero-vector of the correct shape ((1,6)) runs through the network and produces a valid output of the same shape.
#####################################################

#################################################################
# validate end-to-end fault detection
# Verify that device telemetry is flowing into Kafka
# Tail the “raw” topic to see real device messages from MQTT→Kafka:
    # on the Kafka broker pod
kubectl -n kafka exec -it kafka-cluster-kafka-0 -- \
  bin/kafka-console-consumer.sh \
    --bootstrap-server localhost:9092 \
    --topic telemetry-raw \
    --from-beginning
# You should see JSON lines from your bed-sensor, ecg-monitor, etc.

# Confirm the Fault Detector is consuming that topic by watching the logs:
kubectl -n kafka exec -i kafka-cluster-kafka-0 -- \
  bin/kafka-console-producer.sh \
    --broker-list localhost:9092 \
    --topic telemetry-raw <<EOF
{"device_id":"ventilator_01","sensor_readings":[20,350,0,0,0,0],"status":"operational"}
EOF

# The on the other tern=minal
kubectl -n microservices logs -f deployment/fault-detector

# output
    [Kafka] Subscribed to telemetry-raw
    WARNING: This is a development server. Do not use it in a production deployment. Use a production WSGI server instead.
    * Running on all addresses (0.0.0.0)
    * Running on http://127.0.0.1:5004
    * Running on http://10.244.1.7:5004
    Press CTRL+C to quit
    1/1 ━━━━━━━━━━━━━━━━━━━━ 0s 102ms/step
    [FaultDetector] Reconstruction error = 61.833333
    [Alert] Anomaly detected: {'device_id': 'ventilator_01', 'error': 61.833333333333336}
    [ONOS] Flow update responded: 40
#########################################################

# Verify MQTT devices are publishing

# On your edge node, watch the raw MQTT stream:
mosquitto_sub -h localhost -p 1883 -t "devices/#" -v

# Check the Telemetry Collector on the Edge
# Find the container ID for the collector
sudo crictl --runtime-endpoint unix:///run/containerd/containerd.sock ps -a \
  | grep telemetry-collector

# Stream its logs
sudo crictl --runtime-endpoint unix:///run/containerd/containerd.sock logs \
  -f <CONTAINER_ID>

# Inspect the raw Kafka topic
kubectl -n kafka exec -it kafka-cluster-kafka-0 -- \
  bin/kafka-console-consumer.sh \
    --bootstrap-server localhost:9092 \
    --topic telemetry-raw \
    --from-beginning

# do the same for the alerts topic:
kubectl -n kafka exec -it kafka-cluster-kafka-0 -- \
  bin/kafka-console-consumer.sh \
    --bootstrap-server localhost:9092 \
    --topic telemetry-alerts \
    --from-beginning

# Check Fault Detector health & metrics
# Port-forward if you need:
kubectl -n microservices port-forward deploy/fault-detector 5004:5004 &

            # then
            curl http://127.0.0.1:5004/healthz
            # → {"status":"ok"}

            curl http://127.0.0.1:5004/metrics | grep fault_detector
            # → fault_detector_telemetry_processed_total  X.X
            # → fault_detector_anomalies_detected_total  0.0

# Inject an anomaly and watch the pipeline
# Publish a “bad” reading to Kafka:
kubectl -n kafka exec -i kafka-cluster-kafka-0 -- \
  bin/kafka-console-producer.sh \
    --broker-list localhost:9092 \
    --topic telemetry-raw <<EOF
{"device_id":"ventilator_01","device_mac":"00:11:22:33:44:01","sensor_readings":[999,9999,0,0,0,0],"status":"operational"}
EOF

# Verify ONOS flow was pushed
# confirm the new flow rule on ONOS via its REST API:
curl -u onos:rocks \
  http://192.168.56.121:30181/onos/v1/flows/of:0000000000000001

