# Use Python as the base image

# docker build -t your-dockerhub-username/predictive-maintenance:latest .
# docker push your-dockerhub-username/predictive-maintenance:latest


FROM python:3.9

# Set working directory
WORKDIR /app

# Copy application files
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application
COPY . .

# Expose the service port
EXPOSE 5001

# Run the application
CMD ["python", "predictive_maintenance.py"]
