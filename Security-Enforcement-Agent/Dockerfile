# Dockerfile for security_enforcement_agent
FROM python:3.9-slim

WORKDIR /app

# Install dependencies
RUN pip install kafka-python requests schedule prometheus_client flask

# Copy agent script
COPY security_enforcement_agent.py .

CMD ["python", "security_enforcement_agent.py"]
