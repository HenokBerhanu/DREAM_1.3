# cd Fault-Detection-Module/
# docker build -t henok/fault-detector:v3 .
# docker tag henok/fault-detector:v3 henok28/fault-detector:v3
# docker push henok28/fault-detector:v3

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
kubectl -n microservices get pods -l app=fault-detector -o wide

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