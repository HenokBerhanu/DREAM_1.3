# Dockerfile for telemetry-collector

FROM python:3.10-slim

LABEL maintainer="Henok28" \
      description="Telemetry Collector with MQTT and Kafka integration"

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

# Install useful packages for debugging
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc libssl-dev curl iproute2 net-tools iputils-ping && \
    rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -ms /bin/bash collector && chown -R collector:collector /app
USER collector

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the updated telemetry collector script
COPY telemetry_collector.py .

# Expose healthcheck port
EXPOSE 8080

# Add real HEALTHCHECK (assuming you fix /healthz endpoint later)
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD curl -f http://127.0.0.1:8080/healthz || exit 1

ENTRYPOINT ["python", "-u", "telemetry_collector.py"]

# docker build -t your-dockerhub-username/telemetry-collector .
# docker push your-dockerhub-username/telemetry-collector
