# cd Telemetry-Collector-Agent/
# docker build -t henok/telemetry-collector:v1 .
# docker tag henok/telemetry-collector:v1 henok28/telemetry-collector:v1
# docker push henok28/telemetry-collector:v1

vagrant ssh-config MasterNode

# coppy from the host to the edge node
sudo scp -i /home/henok/DREAM_1.3/Kubernetes-deplyment/.vagrant/machines/MasterNode/virtualbox/private_key \
-P 2222 \
~/DREAM_1.3/Telemetry-Collector-Agent/telemetry_collector_daemonset.yaml \
vagrant@127.0.0.1:/home/vagrant/


kubectl apply -f telemetry_collector_daemonset.yaml
# wait for the pod to appear on the edge node
kubectl -n edge-agents get pods -l app=telem-collector -o wide

# tail its log
kubectl -n edge-agents logs -l app=telem-collector -f

/etc/kubeedge/cloudcore.yaml
yaml\nmodules:\n cloudStream:\n enable: true # ← turn on\n streamPort: 10003 # (defaults ok)\n tunnelPort: 10350 # same as commonConfig.tunnelPort\n



