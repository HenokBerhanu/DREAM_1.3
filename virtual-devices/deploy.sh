kubectl apply -f deploy/ventilator_deployment.yaml
kubectl apply -f deploy/ecg_deployment.yaml
kubectl apply -f deploy/infusion_deployment.yaml
kubectl apply -f deploy/wheelchair_deployment.yaml
kubectl apply -f deploy/bed_sensor_deployment.yaml

# docker build -t your-dockerhub-username/ventilator-simulator .
# docker push your-dockerhub-username/ventilator-simulator