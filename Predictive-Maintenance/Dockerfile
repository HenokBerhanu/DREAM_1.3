FROM python:3.9-slim

# ensure logs aren’t buffered
ENV PYTHONUNBUFFERED=1

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt \
 && rm -rf /root/.cache/pip

# add a non-root user
RUN groupadd app && useradd -g app app
COPY . .
USER app

EXPOSE 5001

ENTRYPOINT ["python", "predictive_maintenance.py"]

HEALTHCHECK --interval=30s CMD curl --fail http://localhost:5001/healthz || exit 1
