FROM python:3.10-slim

LABEL maintainer="Henok28" \
      description="Fault Detector Microservice for Smart Healthcare SDN Core Network"

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

# Install system dependencies for TensorFlow and gRPC
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc libatlas-base-dev libhdf5-dev curl \
    && rm -rf /var/lib/apt/lists/*

# Copy and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the fault detection application
COPY fault_detector.py .

# Expose HTTP port for health and metrics
EXPOSE 5004

# Healthcheck
HEALTHCHECK --interval=30s --timeout=5s \
  CMD curl -f http://localhost:5004/healthz || exit 1

# Run the fault detection module
ENTRYPOINT ["python", "-u", "fault_detector.py"]