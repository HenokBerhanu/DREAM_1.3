# 1. build & push image
# cd Policy-Management-System/
# docker build -t henok/policy-manager:v1.1 .
# docker tag henok/policy-manager:v1.1 henok28/policy-manager:v1.1
# docker push henok28/policy-manager:v1.1

vagrant ssh-config MasterNode

# coppy from the host to the master node
sudo scp -i /home/henok/DREAM_1.3/Kubernetes-deplyment/.vagrant/machines/MasterNode/virtualbox/private_key \
-P 2222 \
~/DREAM_1.3/Policy-Management-System/policy_manager_deployment.yaml \
vagrant@127.0.0.1:/home/vagrant/

# 2. deploy manifest
kubectl apply -f policy_manager_deployment.yaml

kubectl -n microservices rollout status deploy/policy-manager
kubectl -n microservices logs -f deploy/policy-manager

# 3. watch it come up
kubectl -n microservices get pods -w
