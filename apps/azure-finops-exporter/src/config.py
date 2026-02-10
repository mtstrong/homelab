"""Configuration for Azure FinOps Exporter."""

import os


class Config:
    """Application configuration loaded from environment variables."""

    # Azure credentials
    AZURE_SUBSCRIPTION_ID: str = os.getenv("AZURE_SUBSCRIPTION_ID", "")
    AZURE_TENANT_ID: str = os.getenv("AZURE_TENANT_ID", "")
    AZURE_CLIENT_ID: str = os.getenv("AZURE_CLIENT_ID", "")
    AZURE_CLIENT_SECRET: str = os.getenv("AZURE_CLIENT_SECRET", "")

    # Cost management settings
    RESOURCE_GROUP_FILTER: str = os.getenv("RESOURCE_GROUP_FILTER", "")
    MONTHLY_BUDGET_USD: float = float(os.getenv("MONTHLY_BUDGET_USD", "50.0"))
    COLLECTION_INTERVAL_SECONDS: int = int(os.getenv("COLLECTION_INTERVAL_SECONDS", "3600"))
    COST_HISTORY_DAYS: int = int(os.getenv("COST_HISTORY_DAYS", "30"))

    # Alerting
    UPTIME_KUMA_PUSH_URL: str = os.getenv("UPTIME_KUMA_PUSH_URL", "")
    BUDGET_ALERT_THRESHOLD: float = float(os.getenv("BUDGET_ALERT_THRESHOLD", "0.8"))

    # Server
    METRICS_PORT: int = int(os.getenv("METRICS_PORT", "8080"))
