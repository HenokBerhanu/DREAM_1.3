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
~/DREAM_1.3/kafka/kafka-topics.yaml \
~/DREAM_1.3/kafka/kafka-user-edgecollector.yaml \
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

########################################################################
###########################################################################
# If the entity operator still being scheduled on the edge node
kubectl label node cloudnode kafka-zone=primary --overwrite

kubectl -n kafka patch deployment kafka-cluster-entity-operator \
  --type=merge \
  -p '{
        "spec": {
          "template": {
            "spec": {
              "nodeSelector": {
                "kafka-zone": "primary"
              }
            }
          }
        }
      }'

kubectl -n kafka delete pod -l strimzi.io/name=kafka-cluster-entity-operator
kubectl -n kafka get pods -w -o wide -l strimzi.io/name=kafka-cluster-entity-operator
#################################################################
####################################################################


#############################################################
# Verify the kafka setup

# Check Kafka Cluster Status (via Strimzi)
kubectl get kafka kafka-cluster -n kafka -o yaml | grep -A 5 status:

# Port-forward Kafka Broker
# This lets you interact with Kafka from your machine via localhost:9094
kubectl -n kafka port-forward kafka-cluster-kafka-0 9094:9094

# On the second terminal
# Produce/Consume Test (using Kafka CLI)
# Install Kafka CLI
sudo apt-get install -y default-jre
wget https://archive.apache.org/dist/kafka/3.6.1/kafka_2.13-3.6.1.tgz
tar -xvzf kafka_2.13-3.6.1.tgz
cd kafka_2.13-3.6.1

# Create a test topic
bin/kafka-topics.sh --bootstrap-server localhost:9094 --create --topic test-topic --partitions 1 --replication-factor 1

# List topics:
bin/kafka-topics.sh --bootstrap-server localhost:9094 --list

# Start producer:
bin/kafka-console-producer.sh --bootstrap-server localhost:9094 --topic test-topic
# then write a few messages (hello, world).

# Start consumer in the third terminal
bin/kafka-console-consumer.sh --bootstrap-server localhost:9094 --topic test-topic --from-beginning
# You should see the messages echoed.
# Now you make sure that
####################################################################


Step 2: create the Kafka topics that the architecture uses and a TLS-authenticated user for the edge Telemetry-Collector agent.
# Kafka topics
kubectl apply -f kafka-topics.yaml -n kafka

# Verify
kubectl get kafkatopics -n kafka

# Apply and wait until the user is Ready
kubectl apply -f kafka-user-edgecollector.yaml
kubectl wait --for=condition=ready kafkauser/edge-collector -n kafka --timeout=120s

# Retrieve the generated secret
kubectl get secret edge-collector -n kafka

# For inspection:
kubectl get secret edge-collector -n kafka -o jsonpath='{.data.ca\.crt}' | base64 -d | openssl x509 -noout -subject

kubectl get kafka kafka-cluster -n kafka -o yaml



##############################################################
Updated setup
#################################################################

# Tear down any existing Kafka install
kubectl delete kafka kafka-cluster -n kafka --ignore-not-found
kubectl delete namespace kafka --ignore-not-found

# Recreate the kafka namespace
kubectl create namespace kafka

# Install the all-in-one 0.45.0 operator YAML
kubectl apply -f \
  https://github.com/strimzi/strimzi-kafka-operator/releases/download/0.45.0/strimzi-cluster-operator-0.45.0.yaml \
  -n kafka

kubectl -n kafka patch deployment strimzi-cluster-operator \
  --type='json' \
  -p='[{"op":"add","path":"/spec/template/spec/nodeSelector","value":{"kubernetes.io/hostname":"cloudnode"}}]'

kubectl apply -f kafka-cluster.yaml -n kafka

kubectl patch kafka kafka-cluster -n kafka --type=merge -p '
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
                      values: ["cloudnode"]
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
                      values: ["cloudnode"]
'
kubectl patch kafka kafka-cluster -n kafka --type=merge -p '
spec:
  entityOperator:
    template:
      pod:
        affinity:
          nodeAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
              nodeSelectorTerms:
                - matchExpressions:
                    - key: kubernetes.io/hostname
                      operator: In
                      values: ["cloudnode"]
'

kubectl delete pod -l strimzi.io/name=kafka-cluster-kafka -n kafka
kubectl delete pod -l strimzi.io/name=kafka-cluster-zookeeper -n kafka
kubectl delete pod -l strimzi.io/name=kafka-cluster-entity-operator -n kafka

kubectl get pods -n kafka -o wide --watch


kubectl get pods -n kafka -w

cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: strimzi-leader-election-role
rules:
  - apiGroups: ["coordination.k8s.io"]
    resources: ["leases"]
    verbs: ["get","list","watch","create","update","patch","delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: strimzi-leader-election-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: strimzi-leader-election-role
subjects:
  - kind: ServiceAccount
    name: strimzi-cluster-operator
    namespace: kafka
EOF

kubectl get pods -n kafka -w





# kafka-cluster-dual-listener.yaml
apiVersion: kafka.strimzi.io/v1beta2
kind: Kafka
metadata:
  name: kafka-cluster
  namespace: kafka              # ← keep the same namespace
spec:
  kafka:
    version: 3.8.0
    replicas: 3

    listeners:
      # ── 1) Internal overlay listener ─────────────────────────────
      - name: plain             # DNS: kafka-cluster-kafka-bootstrap.kafka:9092
        port: 9092
        type: internal
        tls: false

      # ── 2) Existing NodePort listener for edge-node agents ───────
      - name: external          # Reachable at <cloud-node-IP>:9094
        port: 9094
        type: nodeport
        tls: false

    storage:
      type: ephemeral           # keep as-is
  zookeeper:
    replicas: 3
    storage:
      type: ephemeral
  entityOperator:
    topicOperator: {}
    userOperator: {}

#####################################################################################
################################################################################
    # 1 A  Delete the whole namespace – removes pods, PVCs, config-maps, secrets, CRs
kubectl delete namespace kafka --wait --ignore-not-found

# 1 B  Remove all Strimzi cluster-scoped RBAC
kubectl delete clusterrole,clusterrolebinding \
  -l app.kubernetes.io/part-of=strimzi --ignore-not-found

# 1 C  (Optional) remove Strimzi CRDs if you want them gone too
# kubectl delete crd -l app.kubernetes.io/part-of=strimzi


kubectl create namespace kafka

curl -sL https://github.com/strimzi/strimzi-kafka-operator/releases/download/0.45.0/strimzi-cluster-operator-0.45.0.yaml |
  sed 's/namespace: .*/namespace: kafka/' |
  kubectl apply -n kafka -f -

kubectl -n kafka patch deployment strimzi-cluster-operator \
  --type=merge \
  -p '{"spec":{"template":{"spec":{"nodeSelector":{"kubernetes.io/hostname":"cloudnode"}}}}}'


kubectl -n kafka rollout restart deployment strimzi-cluster-operator
kubectl -n kafka rollout status  deployment strimzi-cluster-operator
        # Output
        deployment "strimzi-cluster-operator" successfully rolled out

kubectl -n kafka get pods -o wide -l strimzi.io/kind=cluster-operator




