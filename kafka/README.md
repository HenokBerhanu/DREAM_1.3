# Strimzi 0.45 Kafka Cluster

### **Single‑node deployment on `cloudnode`**

| Component        | Count  |
| ---------------- | ------ |
| Strimzi operator | 1 pod  |
| ZooKeeper        | 3 pods |
| Kafka brokers    | 3 pods |
| Entity‑operator  | 1 pod  |

All eight pods run on the Kubernetes worker **`cloudnode`**.

---

## 0  Prerequisites

| Item        | Requirement                                  |
| ----------- | -------------------------------------------- |
| Kubernetes  | ≥ v1.23 (tested on 1.28)                     |
| Worker node | Hostname **`cloudnode`**, Ready, *no taints* |
| Internet    | `cloudnode` can pull from `quay.io`          |
| kubectl     | Context pointing at the cluster              |

> **Tip:** ensure port **9092** is free on `cloudnode`.

---

## 1  Clean‑slate teardown

```bash
kubectl delete namespace kafka --wait --ignore-not-found
kubectl delete clusterrole,clusterrolebinding \
  -l app.kubernetes.io/part-of=strimzi --ignore-not-found

# (optional) remove CRDs too
# kubectl delete crd -l app.kubernetes.io/part-of=strimzi
```

---

## 2  Namespace

```bash
kubectl create namespace kafka
```

---

## 3  Install Strimzi 0.45 with correct ServiceAccount namespace

```bash
curl -sL https://github.com/strimzi/strimzi-kafka-operator/releases/download/0.45.0/strimzi-cluster-operator-0.45.0.yaml \
| sed 's/namespace: .*/namespace: kafka/' \
| kubectl apply -n kafka -f -
```

### 3.1  Pin the operator to **cloudnode**

```bash
kubectl -n kafka patch deployment strimzi-cluster-operator \
  --type=merge \
  -p '{"spec":{"template":{"spec":{"nodeSelector":{"kubernetes.io/hostname":"cloudnode"}}}}}'

kubectl -n kafka rollout restart deployment strimzi-cluster-operator
kubectl -n kafka rollout status deployment strimzi-cluster-operator
```

---

## 4  Deploy the Kafka cluster

```bash
kubectl -n kafka apply -f kafka-cluster.yaml
```

### 4.1  Ensure ZooKeeper & brokers are pinned

Add inside *kafka-cluster.yaml* **or** run once:

```bash
kubectl -n kafka patch kafka kafka-cluster --type=merge -p '
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
```

---

## 5  Pin the entity‑operator (field absent ≤ 0.45)

```bash
kubectl -n kafka patch deployment kafka-cluster-entity-operator \
  --type=merge \
  -p '{"spec":{"template":{"spec":{"nodeSelector":{"kubernetes.io/hostname":"cloudnode"}}}}}'

kubectl -n kafka patch deployment strimzi-cluster-operator \
  --type=merge \
  -p '{"spec":{"template":{"spec":{"nodeSelector":{"kubernetes.io/hostname":"cloudnode"}}}}}'

kubectl -n kafka get deployment strimzi-cluster-operator \
  -o jsonpath='{.spec.template.spec.nodeSelector}{"\n"}'

# Should print exactly
{"kubernetes.io/hostname":"cloudnode"}

kubectl -n kafka rollout restart deployment strimzi-cluster-operator
kubectl -n kafka rollout status deployment strimzi-cluster-operator

# You should now see:
deployment "strimzi-cluster-operator" successfully rolled out


kubectl -n kafka patch deployment kafka-cluster-entity-operator \
  --type=merge \
  -p '{
        "spec": {
          "template": {
            "spec": {
              "nodeSelector": {
                "kubernetes.io/hostname": "cloudnode"
              }
            }
          }
        }
      }'

kubectl -n kafka patch deployment kafka-cluster-entity-operator \
  --type=merge \
  -p '{
        "spec": {
          "template": {
            "spec": {
              "nodeSelector": {
                "kubernetes.io/hostname": "cloudnode"
              }
            }
          }
        }
      }'

kubectl -n kafka patch deployment kafka-cluster-entity-operator \
  --type=merge \
  -p '{
        "spec": {
          "template": {
            "spec": {
              "nodeSelector": {
                "kubernetes.io/hostname": "cloudnode"
              }
            }
          }
        }
      }'


kubectl -n kafka delete pod -l strimzi.io/name=kafka-cluster-entity-operator
kubectl -n kafka get pods -w -o wide -l strimzi.io/name=kafka-cluster-entity-operator


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


kubectl -n kafka delete pod -l strimzi.io/name=kafka-cluster-entity-operator
```

---

## 6  Verify pod layout

```bash
kubectl -n kafka get pods -o wide
```

All eight pods should show **`NODE cloudnode`** and be *Running*.

---

## 7  Create topics & user

```bash
kubectl -n kafka apply -f kafka-topics.yaml
kubectl -n kafka apply -f kafka-user-edgecollector.yaml
```

---

## 8  Smoke test

```bash
# Producer – type a line then Ctrl‑D
kubectl -n kafka run producer -ti --image=docker.io/bitnami/kafka:3.6 --restart=Never -- \
  kafka-console-producer.sh --bootstrap-server kafka-cluster-kafka-bootstrap:9092 --topic smoke

# Consumer – should echo what you typed
kubectl -n kafka run consumer -ti --image=docker.io/bitnami/kafka:3.6 --restart=Never -- \
  kafka-console-consumer.sh --bootstrap-server kafka-cluster-kafka-bootstrap:9092 --topic smoke \
  --from-beginning --timeout-ms 10000
```