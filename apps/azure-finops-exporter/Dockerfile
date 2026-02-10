FROM python:3.11-slim

LABEL org.opencontainers.image.source="https://github.com/mtstrong/homelab"
LABEL org.opencontainers.image.description="Azure FinOps Exporter — Prometheus metrics for Azure cost data"

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY src/ .

EXPOSE 8080

USER 1000:1000

ENTRYPOINT ["python", "main.py"]
