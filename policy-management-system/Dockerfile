# syntax=docker/dockerfile:1
FROM python:3.11-slim

# Install system packages your app (or wheels) may need
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential curl && \
    rm -rf /var/lib/apt/lists/*

# Create non-root user for better security
ENV APP_USER=policy
RUN useradd --create-home --shell /usr/sbin/nologin $APP_USER

WORKDIR /app

# Copy only requirements first to leverage Docker cache
COPY requirements.txt .

# Install Python deps
RUN pip install --no-cache-dir -r requirements.txt

# Now copy source code
COPY . .

# Use unprivileged user
USER $APP_USER

# Expose service port
EXPOSE 5002

# ── gunicorn is preferred in production instead of flask’s dev server ──
CMD ["gunicorn", "--bind", "0.0.0.0:5002", "policy_manager:app"]
