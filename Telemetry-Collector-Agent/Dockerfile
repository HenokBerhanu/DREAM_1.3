    FROM python:3.10-slim AS base

    # Make Python a little quieter & produce reproducible pyc files
    ENV PYTHONDONTWRITEBYTECODE=1 \
        PYTHONUNBUFFERED=1
    
    WORKDIR /app
    
    # Install only what we need
    COPY requirements.txt .
    RUN pip install --no-cache-dir -r requirements.txt
    
    # Copy the collector
    COPY telemetry_collector.py .
    
    ENTRYPOINT ["python", "-u", "telemetry_collector.py"]
    

# docker build -t your-dockerhub-username/telemetry-collector .
# docker push your-dockerhub-username/telemetry-collector
