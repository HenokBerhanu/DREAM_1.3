# cd Fault-Detection-Module/
# docker build -t henok/fault-detector:v9 .
# docker tag henok/fault-detector:v9 henok28/fault-detector:v9
# docker push henok28/fault-detector:v9

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
{"device_id":"ventilator_01","device_mac":"00:11:22:33:44:01","sensor_readings":[20,350,0,0,0,0],"status":"operational"}
EOF

# Verify ONOS flow was pushed
# confirm the new flow rule on ONOS via its REST API:
curl -u onos:rocks \
  http://192.168.56.121:30181/onos/v1/flows/of:0000000000000001

NODE_IP=192.168.56.121   # your cloudnode
curl -u onos:rocks http://$NODE_IP:30181/onos/v1/flows/of:0000000000000001 | jq .


# Check metrics & health in the cloudnode
curl http://<fault-detector-pod-ip>:5004/healthz
# output
  {"status":"ok"}

curl http://<fault-detector-pod-ip>:5004/metrics | grep fault_detector

# output
    % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                    Dload  Upload   Total   Spent    Left  Speed
    100  2718  100  2718    0     0   8092      0 --:--:-- --:--:-- --:--:--  8113
    # HELP fault_detector_telemetry_processed_total Total number of telemetry messages processed
    # TYPE fault_detector_telemetry_processed_total counter
    fault_detector_telemetry_processed_total 1500.0
    # HELP fault_detector_telemetry_processed_created Total number of telemetry messages processed
    # TYPE fault_detector_telemetry_processed_created gauge
    fault_detector_telemetry_processed_created 1.7464135449756145e+09
    # HELP fault_detector_anomalies_detected_total Total number of anomalies detected
    # TYPE fault_detector_anomalies_detected_total counter
    fault_detector_anomalies_detected_total 1500.0
    # HELP fault_detector_anomalies_detected_created Total number of anomalies detected
    # TYPE fault_detector_anomalies_detected_created gauge
    fault_detector_anomalies_detected_created 1.7464135449756272e+09


###################################################
POD=$(kubectl -n microservices get pod -l app=fault-detector -o name)

kubectl -n microservices exec -i $POD -- \
  python3 - <<'EOF'
import numpy as np, tensorflow as tf, os

# load autoencoder
model = tf.keras.models.load_model(os.environ["MODEL_PATH"], compile=False)

# generate 200 “normal” samples in one go
n = 200
rr = np.random.randint(12, 25, size=n) / 25.0
tv = np.random.rand(n)  # 0–1
zeros = np.zeros((n,4))
X = np.column_stack([rr, tv, zeros])

# batch predict
X_hat = model.predict(X, batch_size=32)

# compute per-sample L1 error
errors = np.mean(np.abs(X - X_hat), axis=1)

# print a suggested 99th percentile threshold
print("suggested ERROR_THRESHOLD ≈", np.percentile(errors, 99))
EOF


# Output
2025-05-05 04:14:30.489300: I external/local_xla/xla/tsl/cuda/cudart_stub.cc:32] Could not find cuda drivers on your machine, GPU will not be used.
2025-05-05 04:14:30.491925: I external/local_xla/xla/tsl/cuda/cudart_stub.cc:32] Could not find cuda drivers on your machine, GPU will not be used.
2025-05-05 04:14:30.575806: E external/local_xla/xla/stream_executor/cuda/cuda_fft.cc:467] Unable to register cuFFT factory: Attempting to register factory for plugin cuFFT when one has already been registered
WARNING: All log messages before absl::InitializeLog() is called are written to STDERR
E0000 00:00:1746418470.589408   16798 cuda_dnn.cc:8579] Unable to register cuDNN factory: Attempting to register factory for plugin cuDNN when one has already been registered
E0000 00:00:1746418470.593408   16798 cuda_blas.cc:1407] Unable to register cuBLAS factory: Attempting to register factory for plugin cuBLAS when one has already been registered
W0000 00:00:1746418470.680218   16798 computation_placer.cc:177] computation placer already registered. Please check linkage and avoid linking the same target more than once.
W0000 00:00:1746418470.680243   16798 computation_placer.cc:177] computation placer already registered. Please check linkage and avoid linking the same target more than once.
W0000 00:00:1746418470.680246   16798 computation_placer.cc:177] computation placer already registered. Please check linkage and avoid linking the same target more than once.
W0000 00:00:1746418470.680248   16798 computation_placer.cc:177] computation placer already registered. Please check linkage and avoid linking the same target more than once.
2025-05-05 04:14:30.683717: I tensorflow/core/platform/cpu_feature_guard.cc:210] This TensorFlow binary is optimized to use available CPU instructions in performance-critical operations.
To enable the following instructions: AVX2, in other operations, rebuild TensorFlow with the appropriate compiler flags.
2025-05-05 04:14:39.594357: E external/local_xla/xla/stream_executor/cuda/cuda_platform.cc:51] failed call to cuInit: INTERNAL: CUDA error: Failed call to cuInit: UNKNOWN ERROR (303)
7/7 ━━━━━━━━━━━━━━━━━━━━ 1s 49ms/step 
suggested ERROR_THRESHOLD ≈ 0.3887466727330152
######################################################################

# Update your Deployment’s ERROR_THRESHOLD
# Edit your fault-detector Deployment
kubectl -n microservices patch deployment fault-detector --type=json -p='[
  {
    "op": "replace",
    "path": "/spec/template/spec/containers/0/env/5/value",
    "value": "0.386"
  }
]'


kubectl -n microservices rollout restart deployment fault-detector
kubectl -n microservices rollout status deployment fault-detector

# simulate a perfectly normal ventilator reading:
kubectl -n kafka exec -i kafka-cluster-kafka-0 -- \
  bin/kafka-console-producer.sh \
    --broker-list localhost:9092 \
    --topic telemetry-raw <<EOF
{
  "device_id":"ventilator_01",
  "device_mac":"00:11:22:33:44:01",
  "sensor_readings":[0.8,0.7,0,0,0,0],
  "status":"operational"
}
EOF

# The on the other tern=minal
kubectl -n microservices logs -f deployment/fault-detector

# Trigger a real anomaly by sending a value outside the normal normalized range:
kubectl -n kafka exec -i kafka-cluster-kafka-0 -- \
  bin/kafka-console-producer.sh \
    --broker-list localhost:9092 \
    --topic telemetry-raw <<EOF
{
  "device_id":"ventilator_01",
  "device_mac":"00:11:22:33:44:01",
  "sensor_readings":[1.5,1.2,0,0,0,0],
  "status":"operational"
}
EOF

# The on the other tern=minal
kubectl -n microservices logs -f deployment/fault-detector

