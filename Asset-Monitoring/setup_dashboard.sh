# 1. build & push image
# cd Asset-Monitoring/
# docker build -t henok/asset-monitoring-dashboard:v1.0 .
# docker tag henok/asset-monitoring-dashboard:v1.0 henok28/asset-monitoring-dashboard:v1.0
# docker push henok28/asset-monitoring-dashboard:v1.0

vagrant ssh-config MasterNode

# coppy from the host to the master node
sudo scp -i /home/henok/DREAM_1.3/Kubernetes-deplyment/.vagrant/machines/MasterNode/virtualbox/private_key \
-P 2222 \
~/DREAM_1.3/Asset-Monitoring/asset_monitoring_dashboard_deployment.yaml \
vagrant@127.0.0.1:/home/vagrant/

# in repo root
kubectl apply -f asset_monitoring_dashboard_deployment.yaml

# watch until everything is ready
kubectl -n microservices get pods -w

# The dashboard will be reachable from your host machine at:
http://<cloudnode‑IP>:32003/

# Grafana UI (user admin / password grafana) is at:
http://<cloudnode‑IP>:32030/

# From within Grafana add a Prometheus data‑source pointing to http://<prometheus‑svc>:9090 (or any other source you use) and import the sample "Asset‑Alerts" dashboard to visualise the Prometheus metrics exposed by /metrics.