FROM python:3.9-slim

# ensure logs aren’t buffered
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# install runtime dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt \
 && rm -rf /root/.cache/pip

# copy the application code
COPY predictive_maintenance.py .

# create and populate the models directory
RUN mkdir -p /models
COPY models/autoencoder_model.h5 /models/autoencoder_model.h5

# drop to a non-root user for security
RUN groupadd app && useradd -g app app
USER app

# expose health/metrics port
EXPOSE 5001

ENTRYPOINT ["python", "predictive_maintenance.py"]

# lightweight healthcheck
HEALTHCHECK --interval=30s \
  CMD curl --fail http://localhost:5001/healthz || exit 1