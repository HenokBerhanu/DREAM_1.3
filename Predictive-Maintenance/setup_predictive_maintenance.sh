# cd Predictive-Maintenance/
# docker build -t henok/predictive-maintenance:v1.1 .
# docker tag henok/predictive-maintenance:v1.1 henok28/predictive-maintenance:v1.1
# docker push henok28/predictive-maintenance:v1.1

vagrant ssh-config MasterNode

# coppy from the host to the master node
sudo scp -i /home/henok/DREAM_1.3/Kubernetes-deplyment/.vagrant/machines/MasterNode/virtualbox/private_key \
-P 2222 \
~/DREAM_1.3/Predictive-Maintenance/predictive_maintenance_deployment.yaml \
vagrant@127.0.0.1:/home/vagrant/

# Train and generate autoencoder model in the host machin
pip install \
  numpy \
  pandas \
  tensorflow

sudo chmod +x generate_telemetry.py
export OUT_CSV=/home/henok/DREAM_1.3/Predictive-Maintenance/models/telemetry.csv
export N_PER_TYPE=1000
python3 generate_telemetry.py

sudo chmod +x generate_model.py
python3 generate_model.py

# coppy the pvc to the master node
          sudo scp -i /home/henok/DREAM_1.3/Kubernetes-deplyment/.vagrant/machines/MasterNode/virtualbox/private_key \
          -P 2222 \
          ~/DREAM_1.3/Predictive-Maintenance/models/autoencoder_model.h5 \
          vagrant@127.0.0.1:/home/vagrant/

# create microservices ns
kubectl create ns microservices

# Create the ConfigMap for your trained model
          # kubectl -n microservices create configmap predictive-maintenance-config \
          #   --from-file=autoencoder_model.h5=/home/vagrant/autoencoder_model.h5 \
          #   --dry-run=client -o yaml | kubectl apply -f -
kubectl -n microservices create configmap predictive-maintenance-model \
  --from-file=autoencoder_model.h5=/home/vagrant/autoencoder_model.h5

# Apply the Deployment & Service
kubectl apply -f predictive_maintenance_deployment.yaml

# Verify the rollout
kubectl -n microservices rollout status deploy/predictive-maintenance
kubectl -n microservices rollout restart deployment/predictive-maintenance
kubectl -n microservices get pods -l app=predictive-maintenance -o wide

#####################################################
Smoke test
##############################################
# Verify Pod & Endpoints

# make sure the pod is Running & Ready
kubectl -n microservices get pods -l app=predictive-maintenance

# hit the health and metrics endpoints
kubectl -n microservices port-forward svc/predictive-maintenance 5001:5001 &

# in another shell:
curl -s http://127.0.0.1:5001/healthz
# → {"status":"ok"}

curl -s http://127.0.0.1:5001/metrics | head -n5
# → should show your Prometheus counters
#####################################################
# tail the service logs
kubectl -n microservices logs -l app=predictive-maintenance -f

# Consume maintenance alerts
# Open a Kafka console consumer on your Alert topic:
kubectl -n kafka exec -ti kafka-cluster-kafka-0 -- \
  bin/kafka-console-consumer.sh \
    --bootstrap-server localhost:9092 \
    --topic maintenance-alerts \
    --from-beginning

# Send a “normal” telemetry message
# Post a JSON that yields a low reconstruction error:
kubectl -n kafka exec -i kafka-cluster-kafka-0 -- \
  bin/kafka-console-producer.sh \
    --broker-list localhost:9092 \
    --topic telemetry-raw <<EOF
{"device_id":"ventilator_01","device_mac":"00:11:22:33:44:01","sensor_readings":[0.5,0.4,0,0,0,0]}
EOF

kubectl -n kafka exec -i kafka-cluster-kafka-0 -- \
bash -c 'cat <<EOF | sed "/^$/d" | bin/kafka-console-producer.sh --broker-list localhost:9092 --topic telemetry-raw
{"device_id":"ventilator_01","device_mac":"00:11:22:33:44:01","sensor_readings":[0.72,0.80,0,0,0,0]}
{"device_id":"ventilator_02","device_mac":"00:11:22:33:44:02","sensor_readings":[0.60,0.65,0,0,0,0]}
{"device_id":"ventilator_03","device_mac":"00:11:22:33:44:03","sensor_readings":[0.88,0.75,0,0,0,0]}
{"device_id":"ecg_monitor_01","device_mac":"00:11:22:33:44:41","sensor_readings":[0.80,0,0,0,0,0]}
{"device_id":"ecg_monitor_02","device_mac":"00:11:22:33:44:42","sensor_readings":[0.65,0,0,0,0,0]}
{"device_id":"ecg_monitor_03","device_mac":"00:11:22:33:44:43","sensor_readings":[0.90,0,0,0,0,0]}
{"device_id":"infusion_pump_01","device_mac":"00:11:22:33:44:21","sensor_readings":[0.60,0,0,0,0,0]}
{"device_id":"infusion_pump_02","device_mac":"00:11:22:33:44:22","sensor_readings":[0.30,0,0,0,0,0]}
{"device_id":"infusion_pump_03","device_mac":"00:11:22:33:44:23","sensor_readings":[0.80,0,0,0,0,0]}
{"device_id":"wheelchair_01","device_mac":"00:11:22:33:44:31","sensor_readings":[0.60,0.917,0.60,0,0,0]}
{"device_id":"wheelchair_02","device_mac":"00:11:22:33:44:32","sensor_readings":[0.80,0.83,0.40,0,0,0]}
{"device_id":"wheelchair_03","device_mac":"00:11:22:33:44:33","sensor_readings":[0.50,1.00,0.80,0,0,0]}
{"device_id":"bed_sensor_01","device_mac":"00:11:22:33:44:11","sensor_readings":[0,0,0,0,0,0]}
{"device_id":"bed_sensor_02","device_mac":"00:11:22:33:44:12","sensor_readings":[1,0,0,0,0,0]}
{"device_id":"bed_sensor_03","device_mac":"00:11:22:33:44:13","sensor_readings":[0,0,0,0,0,0]}
EOF'




# Send an anomalous telemetry message
# Use readings outside your normal bounds:
kubectl -n kafka exec -i kafka-cluster-kafka-0 -- \
  bin/kafka-console-producer.sh \
    --broker-list localhost:9092 \
    --topic telemetry-raw <<EOF
{"device_id":"ventilator_01","device_mac":"00:11:22:33:44:01","sensor_readings":[1.5,1.2,0,0,0,0]}
EOF


# Test the REST endpoint
curl -s -XPOST http://127.0.0.1:5001/predict \
  -H 'Content-Type: application/json' \
  -d '{"sensor_readings":[1.5,1.2,0,0,0,0]}' | jq .
# → {"status":"anomaly","error": ...}

kubectl -n microservices set env deployment/predictive-maintenance ERROR_THRESHOLD=0.386
kubectl -n microservices rollout restart deployment/predictive-maintenance

