kubectl apply -f kafka-test.yaml
# wait a few seconds – Strimzi creates Secret/test-app with certs & key
kubectl get secret test-app -n kafka

kubectl apply -f kafka-producer.yaml
# The Job exits almost instantly after sending one message



kubectl apply -f kafka-consumer.yaml
# give it ~10 seconds, then:
kubectl logs job/kafka-consumer -n kafka
     # Expected log
     hello-microservices
     Processed a total of 1 messages
      # If you see that exact output, Kafka is fully validated under TLS, ACL, and Flannel networking.


# Clean-up the scratch artifacts
# kubectl delete job kafka-producer kafka-consumer -n kafka --ignore-not-found
kubectl delete jobs kafka-producer kafka-consumer -n kafka
kubectl delete kafkatopic telemetry-test -n kafka
kubectl delete kafkauser test-app -n kafka

vagrant ssh-config MasterNode

# coppy from the host to the edge node
sudo scp -i /home/henok/DREAM_1.3/Kubernetes-deplyment/.vagrant/machines/MasterNode/virtualbox/private_key \
-P 2222 \
~/DREAM_1.3/kafka/producer-consumer-test/kafka-consumer.yaml \
~/DREAM_1.3/kafka/producer-consumer-test/kafka-producer.yaml \
~/DREAM_1.3/kafka/producer-consumer-test/kafka-test.yaml \
vagrant@127.0.0.1:/home/vagrant/

sudo mv kafka-consumer.yaml kafka-producer.yaml kafka-test.yaml ~/producer-consumer-test