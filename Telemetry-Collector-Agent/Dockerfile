FROM python:3.9
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY telemetry_collector.py .
CMD ["python", "telemetry_collector.py"]

# docker build -t your-dockerhub-username/telemetry-collector .
# docker push your-dockerhub-username/telemetry-collector
