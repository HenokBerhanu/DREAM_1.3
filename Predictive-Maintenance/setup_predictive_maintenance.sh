# cd Predictive-Maintenance/
# docker build -t henok/predictive-maintenance:v1.0 .
# docker tag henok/predictive-maintenance:v1.0 henok28/predictive-maintenance:v1.0
# docker push henok28/predictive-maintenance:v1.0

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
export OUT_CSV=~/telemetry.csv
export N_PER_TYPE=500
python3 generate_telemetry.py

python3 train_autoencoder_pm.py

# coppy the model to the master node
sudo scp -i /home/henok/DREAM_1.3/Kubernetes-deplyment/.vagrant/machines/MasterNode/virtualbox/private_key \
-P 2222 \
~/DREAM_1.3/Predictive-Maintenance/predictive_model.h5 \
vagrant@127.0.0.1:/home/vagrant/

# create microservices ns
kubectl create ns microservices

# Create the ConfigMap for your trained model
kubectl -n microservices create configmap fault-detector-model \
  --from-file=predictive_model.h5=/home/vagrant/predictive_model.h5 \
  --dry-run=client -o yaml | kubectl apply -f -

# Apply the Deployment & Service
kubectl apply -f fault_detector_deployment.yaml

# Verify the rollout
kubectl -n microservices rollout status deploy/fault-detector
kubectl -n microservices rollout restart deployment/fault-detector
kubectl -n microservices get pods -l app=fault-detector -o wide