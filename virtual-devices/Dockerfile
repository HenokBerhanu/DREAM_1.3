FROM python:3.9
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
CMD ["python", "ventilator.py"]
# override the CMD in Kubernetes to run each specific script

# docker build -t your-dockerhub-username/virtual-medical-device .
# docker push your-dockerhub-username/virtual-medical-device
