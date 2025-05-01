# Fault Detection Module

This folder contains the Fault Detection microservice for the Smart Healthcare SDN architecture (DREAM objective 1.3). From initial prototype to production‑ready service, we’ve:

1. **Modeled and trained** an autoencoder on synthetic telemetry data.
2. **Packaged** the model and code in a container, using a ConfigMap for runtime injection.
3. **Implemented** a Kafka-based ingestion loop that:
   - Consumes raw telemetry from the `telemetry-raw` topic.
   - Computes reconstruction error via the autoencoder.
   - Flags anomalies above a configurable threshold.
   - Publishes fault alerts back to the `telemetry-alerts` topic.
4. **Integrated** with ONOS (SDN controller) via REST to trigger flow reconfiguration.
5. **Instrumented** the service with Prometheus counters for observability.

---

## Architecture Overview

```text
Devices (MQTT) → Telemetry Collector (Kafka) → Fault Detector →
  ├─ Kafka alerts topic
  └─ ONOS REST API (flow updates)

Prometheus → HTTP /metrics (Fault Detector)
```

- **Data plane**: devices publish over MQTT → Kafka
- **Control plane**: Fault Detector subscribes to Kafka
- **Observability**: Prometheus scrapes `/metrics`

---

## Prerequisites

- Kubernetes 1.20+ with namespaces `edge-agents`, `kafka`, `microservices`
- Strimzi Kafka cluster in namespace `kafka`
- ONOS controller reachable via its REST API
- `kubectl`, Docker (or another OCI registry)

---

## Model Generation

We generate a simple autoencoder on synthetic telemetry features. Run locally or on your build host:

```bash
# Install deps
pip install tensorflow numpy

# Train & save model
python build_autoencoder.py
# → produces autoencoder_model.h5
```

The helper script `build_autoencoder.py` lives in this repo.

---

## ConfigMap: Model Injection

Package your `autoencoder_model.h5` into Kubernetes via:

```bash
kubectl -n microservices create configmap fault-detector-model \
    --from-file=autoencoder_model.h5=./autoencoder_model.h5 \
    --dry-run=client -o yaml | kubectl apply -f -
```

This makes the model available at `/models/autoencoder_model.h5` inside the pod.

---

## Requirements & Dockerfile Updates

### requirements.txt
```text
flask
kafka-python
tensorflow
grpcio
requests
numpy
h5py
prometheus_client
```

### Dockerfile (excerpt)
```dockerfile
# Install HDF5 libs
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc libatlas-base-dev libhdf5-dev curl && rm -rf /var/lib/apt/lists/*

# Install Python deps
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy code
COPY fault_detector.py .

ENTRYPOINT ["python", "-u", "fault_detector.py"]
```  

---

## Deployment

Apply the Kubernetes Deployment:

```bash
kubectl apply -n microservices -f fault_detector_deployment.yaml
```

Key points:
- Mounts `model-volume` from the `fault-detector-model` ConfigMap at `/models`
- Sets `MODEL_PATH=/models/autoencoder_model.h5`
- Exposes port `5004` for health & metrics

Then rollout:
```bash
kubectl -n microservices rollout status deployment fault-detector
```

---

## Environment Variables

| Name                 | Default                                    | Description                         |
|----------------------|--------------------------------------------|-------------------------------------|
| `KAFKA_BOOTSTRAP`    | `kafka-cluster-kafka-bootstrap.kafka:9092` | Kafka bootstrap server             |
| `TELEMETRY_TOPIC`    | `telemetry-raw`                            | Input telemetry topic               |
| `ALERT_TOPIC`        | `telemetry-alerts`                         | Output alerts topic                 |
| `ONOS_URL`           | `http://onos-service:8181/onos/v1`         | SDN controller REST API base URL    |
| `ONOS_AUTH_USER`     | `onos`                                     | ONOS username                       |
| `ONOS_AUTH_PASS`     | `rocks`                                    | ONOS password                       |
| `MODEL_PATH`         | `/models/autoencoder_model.h5`             | Path to `.h5` model file            |
| `ERROR_THRESHOLD`    | `0.05`                                     | Reconstruction error threshold      |
| `HTTP_PORT`          | `5004`                                     | Flask health & metrics port         |

---

## Observability & Testing

1. **Health Check**:
   ```bash
   kubectl -n microservices port-forward deploy/fault-detector 5004:5004
   curl http://127.0.0.1:5004/healthz  # {"status":"ok"}
   ```

2. **Metrics**:
   ```bash
   curl http://127.0.0.1:5004/metrics
   # Should include:
   #   fault_detector_telemetry_processed_total
   #   fault_detector_anomalies_detected_total
   ```

3. **Kafka Logs**:
   ```bash
   kubectl -n microservices logs -f deployment/fault-detector
   # Look for subscription + error logs:
   # [Kafka] Subscribed to telemetry-raw
   # [FaultDetector] Reconstruction error = 0.012345
   ```

4. **Consumer Group Lag** (on Kafka broker pod):
   ```bash
   kubectl -n kafka exec -it kafka-cluster-kafka-0 -- \
     bin/kafka-consumer-groups.sh \
       --bootstrap-server localhost:9092 \
       --describe --group fault-detector-group
   ```

---

## Contributing

1. Fork this repo.
2. Branch: `feature/your-idea`.
3. Commit & push.
4. Create a Pull Request.

Please ensure you update:
- `requirements.txt` for new Python deps
- Dockerfile system packages if needed
- Deployment YAML for any new env vars or mounts

---

