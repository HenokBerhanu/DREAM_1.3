FROM python:3.9
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 5002
CMD ["python", "policy_manager.py"]

# docker build -t your-dockerhub-username/policy-manager:latest .
# docker push your-dockerhub-username/policy-manager:latest