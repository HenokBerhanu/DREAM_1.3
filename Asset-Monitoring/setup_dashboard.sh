# 1. build & push image
cd Asset-Monitoring/
docker build -t henok/asset-monitoring-dashboard:v1.3 .
docker tag henok/asset-monitoring-dashboard:v1.3 henok28/asset-monitoring-dashboard:v1.3
docker push henok28/asset-monitoring-dashboard:v1.3

vagrant ssh-config MasterNode

# coppy from the host to the master node
sudo scp -i /home/henok/DREAM_1.3/Kubernetes-deplyment/.vagrant/machines/MasterNode/virtualbox/private_key \
-P 2222 \
~/DREAM_1.3/Asset-Monitoring/asset_monitoring_dashboard_deployment.yaml \
vagrant@127.0.0.1:/home/vagrant/

# in repo root
kubectl apply -f asset_monitoring_dashboard_deployment.yaml
kubectl -n microservices rollout status deploy/asset-monitoring-dashboard
kubectl -n microservices logs <POD_NAME>

kubectl -n microservices scale deploy/asset-monitoring-dashboard --replicas=0
# wait a few seconds until no pods remain
kubectl -n microservices scale deploy/asset-monitoring-dashboard --replicas=1


# watch until everything is ready
kubectl -n microservices get pods -w

# The dashboard will be reachable from your host machine at:
http://<cloudnode‑IP>:32003/
http://192.168.56.121:32003/
http://192.168.56.121:32003/

# Grafana UI (user admin / password grafana) is at:
http://<cloudnode‑IP>:32030/
http://192.168.56.121:32030/

# Asset dashboard health
curl -I http://<cloudnode-IP>:32003/healthz
curl -I http://192.168.56.121:32003/healthz

# Grafana health
curl -I http://192.168.56.121:32030/api/health

# Prometheus health
curl -I http://192.168.56.121:9090/-/ready


# From within Grafana add a Prometheus data‑source pointing to http://<prometheus‑svc>:9090 (or any other source you use) and import the sample "Asset‑Alerts" dashboard to visualise the Prometheus metrics exposed by /metrics.

# Find your Grafana service’s NodePort:
kubectl -n microservices get svc grafana


sudo scp -i /home/henok/DREAM_1.3/Kubernetes-deplyment/.vagrant/machines/MasterNode/virtualbox/private_key \
-P 2222 \
~/DREAM_1.3/Asset-Monitoring/prometheus.yaml \
vagrant@127.0.0.1:/home/vagrant/



# then restart the Prometheus Deployment:
kubectl apply -f prometheus.yaml
kubectl rollout restart deployment/prometheus -n microservices
kubectl rollout status deployment/prometheus -n microservices

kubectl apply -f security-agent-deployment.yaml
kubectl rollout restart daemonset/security-enforcement-agent -n edge-agents
kubectl rollout status   daemonset/security-enforcement-agent -n edge-agents

kubectl -n microservices get pods -l app=prometheus
kubectl -n microservices get svc prometheus-server

# inside the VM
kubectl -n microservices port-forward --address 0.0.0.0 svc/prometheus-server 30090:9090
# then on host
http://192.168.56.121:30090

# On the edge node
sudo crictl ps -a | grep security-enforcement-agent # or telemetry-collector
sudo crictl logs 9cb46df9cef82