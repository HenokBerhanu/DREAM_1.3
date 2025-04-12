FROM python:3.9
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 5004
CMD ["python", "fault_detector.py"]

# docker build -t your-dockerhub-username/fault-detector:latest .
# docker push your-dockerhub-username/fault-detector:latest

