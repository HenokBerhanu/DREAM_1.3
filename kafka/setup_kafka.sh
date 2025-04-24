# 2. Create kafka namespace
kubectl create namespace kafka

kubectl apply -f https://strimzi.io/install/latest?namespace=kafka -n kafka

kubectl -n kafka patch deployment strimzi-cluster-operator \
  --type='json' \
  -p='[{"op": "add", "path": "/spec/template/spec/nodeSelector", "value": {"kubernetes.io/hostname": "cloudnode"}}]'


kubectl get pods -n kafka -l strimzi.io/kind=cluster-operator -o wide

vagrant ssh-config MasterNode

# coppy from the host to the edge node
sudo scp -i /home/henok/DREAM_1.3/Kubernetes-deplyment/.vagrant/machines/MasterNode/virtualbox/private_key \
-P 2222 \
~/DREAM_1.3/kafka/kafka-values.yaml \
vagrant@127.0.0.1:/home/vagrant/

kubectl patch kafka kafka-cluster -n kafka --type='merge' -p '
spec:
  kafka:
    template:
      pod:
        affinity:
          nodeAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
              nodeSelectorTerms:
              - matchExpressions:
                - key: kubernetes.io/hostname
                  operator: In
                  values:
                  - cloudnode
  zookeeper:
    template:
      pod:
        affinity:
          nodeAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
              nodeSelectorTerms:
              - matchExpressions:
                - key: kubernetes.io/hostname
                  operator: In
                  values:
                  - cloudnode
'

# 3. Apply the Kafka Cluster Manifest:
kubectl apply -f kafka-values.yaml -n kafka

kubectl get pods -n kafka -o wide
NAME                                       READY   STATUS    RESTARTS      AGE     IP            NODE        NOMINATED NODE   READINESS GATES
kafka-cluster-zookeeper-0                  1/1     Running   0             5m23s   10.244.1.49   cloudnode   <none>           <none>
kafka-cluster-zookeeper-1                  1/1     Running   0             5m23s   10.244.1.51   cloudnode   <none>           <none>
kafka-cluster-zookeeper-2                  1/1     Running   0             5m23s   10.244.1.50   cloudnode   <none>           <none>
strimzi-cluster-operator-ff6855fdc-mphds   1/1     Running   1 (55m ago)   64m     10.244.1.44   cloudnode   <none>           <none>

kubectl get pods -n kafka -l strimzi.io/kind=Kafka
NAME                        READY   STATUS    RESTARTS   AGE
kafka-cluster-zookeeper-0   1/1     Running   0          6m2s
kafka-cluster-zookeeper-1   1/1     Running   0          6m2s
kafka-cluster-zookeeper-2   1/1     Running   0          6m2s

kubectl get pods -n kafka -l strimzi.io/kind=Kafka
NAME                        READY   STATUS    RESTARTS   AGE
kafka-cluster-zookeeper-0   1/1     Running   0          8m20s
kafka-cluster-zookeeper-1   1/1     Running   0          8m20s
kafka-cluster-zookeeper-2   1/1     Running   0          8m20s
vagrant@MasterNode:~$ kubectl get kafka -n kafka
NAME            DESIRED KAFKA REPLICAS   DESIRED ZK REPLICAS   READY   METADATA STATE   WARNINGS
kafka-cluster   3                        3                                              True

kubectl delete pod kafka-cluster-zookeeper-0 kafka-cluster-zookeeper-2 kafka-cluster-zookeeper-1 -n kafka

kubectl patch kafka kafka-cluster -n kafka --type='json' -p='[
  {"op": "remove", "path": "/spec/zookeeper/template/pod/affinity"}
]'

kubectl delete pod -l strimzi.io/name=kafka-cluster-zookeeper -n kafka


kubectl run dns-check --rm -i -t \
  --image=infoblox/dnstools \
  --restart=Never \
  --namespace=kafka \
  --overrides='{
    "spec": {
      "nodeSelector": {
        "kubernetes.io/hostname": "cloudnode"
      },
      "dnsPolicy": "ClusterFirst",
      "containers": [{
        "name": "dns-check",
        "image": "infoblox/dnstools",
        "command": ["sh"],
        "stdin": true,
        "tty": true
      }]
    }
  }'

nslookup kafka-cluster-zookeeper-0.kafka-cluster-zookeeper-nodes.kafka.svc.cluster.local

kubectl patch kafka kafka-cluster -n kafka --type='merge' -p '{
  "spec": {
    "entityOperator": {
      "template": {
        "pod": {
          "affinity": {
            "nodeAffinity": {
              "requiredDuringSchedulingIgnoredDuringExecution": {
                "nodeSelectorTerms": [
                  {
                    "matchExpressions": [
                      {
                        "key": "kubernetes.io/hostname",
                        "operator": "In",
                        "values": ["cloudnode"]
                      }
                    ]
                  }
                ]
              }
            }
          }
        }
      }
    }
  }
}'
kubectl delete pod -n kafka -l strimzi.io/name=kafka-cluster-entity-operator
kubectl get pod -n kafka -l strimzi.io/name=kafka-cluster-entity-operator -o wide


