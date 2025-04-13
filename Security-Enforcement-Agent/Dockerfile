FROM python:3.9
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
CMD ["python", "enforcement_agent.py"]

# docker build -t your-dockerhub-username/security-agent .
# docker push your-dockerhub-username/security-agent
