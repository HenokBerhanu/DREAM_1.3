vagrant ssh-config MasterNode

# coppy from the host to the edge node
sudo scp -i /home/henok/DREAM_1.3/Kubernetes-deplyment/.vagrant/machines/MasterNode/virtualbox/private_key \
-P 2222 \
~/DREAM_1.3/virtual-devices/devices.yaml \
vagrant@127.0.0.1:/home/vagrant/

kubectl create namespace smart-hospital

kubectl apply -f devices.yaml

kubectl get devices -n smart-hospital -o wide

sudo systemctl restart bed-sensor
sudo systemctl restart ecg-monitor
sudo systemctl restart infusion-pump
sudo systemctl restart ventilator
sudo systemctl restart wheelchair


sudo systemctl daemon-reload
sudo systemctl restart bed-sensor
sudo systemctl status bed-sensor

sudo systemctl status bed-sensor ecg-monitor infusion-pump ventilator wheelchair











