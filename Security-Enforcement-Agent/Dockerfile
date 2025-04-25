# Base image
FROM python:3.9-slim

# Metadata labels
LABEL maintainer="Henok28" \
      description="Security Enforcement Agent with Kafka, Prometheus, Flask, and ONOS/OVS integration"

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

# Set working directory
WORKDIR /app

# Install system dependencies (curl helps with debugging if needed)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl iproute2 iputils-ping net-tools \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install -r requirements.txt

# Copy agent script
COPY security_enforcement_agent.py .

# Expose Prometheus and Flask ports
EXPOSE 9000 5005

# Command to run the agent
CMD ["python", "security_enforcement_agent.py"]
