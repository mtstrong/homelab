"""Azure Cost Management API collector.

Queries the Azure Cost Management REST API for cost data including:
- Month-to-date totals by service and resource group
- Daily cost breakdown for trend analysis
- Per-resource cost allocation
"""

import logging
from datetime import datetime, timedelta
from typing import Any

import requests
from azure.identity import ClientSecretCredential

from config import Config

logger = logging.getLogger(__name__)

API_VERSION = "2023-11-01"


class AzureCostCollector:
    """Collects cost data from Azure Cost Management API."""

    def __init__(self, config: Config) -> None:
        self.config = config
        self.subscription_id = config.AZURE_SUBSCRIPTION_ID
        self.credential = ClientSecretCredential(
            tenant_id=config.AZURE_TENANT_ID,
            client_id=config.AZURE_CLIENT_ID,
            client_secret=config.AZURE_CLIENT_SECRET,
        )
        self.base_url = (
            f"https://management.azure.com"
            f"/subscriptions/{self.subscription_id}"
            f"/providers/Microsoft.CostManagement/query"
            f"?api-version={API_VERSION}"
        )

    def _headers(self) -> dict[str, str]:
        token = self.credential.get_token("https://management.azure.com/.default")
        return {
            "Authorization": f"Bearer {token.token}",
            "Content-Type": "application/json",
        }

    def _query(self, payload: dict[str, Any]) -> dict[str, Any]:
        """Execute a Cost Management query and return parsed response."""
        resp = requests.post(self.base_url, json=payload, headers=self._headers(), timeout=60)
        resp.raise_for_status()
        return resp.json()

    # ------------------------------------------------------------------
    # Public collection methods
    # ------------------------------------------------------------------

    def get_monthly_costs_by_service(self) -> dict[str, Any]:
        """Month-to-date costs grouped by ServiceName and ResourceGroup with daily granularity."""
        now = datetime.utcnow()
        start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)

        payload = {
            "type": "ActualCost",
            "timeframe": "Custom",
            "timePeriod": {
                "from": start.strftime("%Y-%m-%dT00:00:00Z"),
                "to": now.strftime("%Y-%m-%dT23:59:59Z"),
            },
            "dataset": {
                "granularity": "Daily",
                "aggregation": {
                    "totalCost": {"name": "Cost", "function": "Sum"},
                },
                "grouping": [
                    {"type": "Dimension", "name": "ServiceName"},
                    {"type": "Dimension", "name": "ResourceGroup"},
                ],
            },
        }
        return self._query(payload)

    def get_daily_totals(self, days: int | None = None) -> dict[str, Any]:
        """Daily cost totals for the last *days* days (default from config)."""
        days = days or self.config.COST_HISTORY_DAYS
        now = datetime.utcnow()
        start = now - timedelta(days=days)

        payload = {
            "type": "ActualCost",
            "timeframe": "Custom",
            "timePeriod": {
                "from": start.strftime("%Y-%m-%dT00:00:00Z"),
                "to": now.strftime("%Y-%m-%dT23:59:59Z"),
            },
            "dataset": {
                "granularity": "Daily",
                "aggregation": {
                    "totalCost": {"name": "Cost", "function": "Sum"},
                },
            },
        }
        return self._query(payload)

    def get_resource_costs(self) -> dict[str, Any]:
        """Month-to-date costs grouped by individual resource."""
        now = datetime.utcnow()
        start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)

        payload = {
            "type": "ActualCost",
            "timeframe": "Custom",
            "timePeriod": {
                "from": start.strftime("%Y-%m-%dT00:00:00Z"),
                "to": now.strftime("%Y-%m-%dT23:59:59Z"),
            },
            "dataset": {
                "granularity": "None",
                "aggregation": {
                    "totalCost": {"name": "Cost", "function": "Sum"},
                },
                "grouping": [
                    {"type": "Dimension", "name": "ResourceId"},
                    {"type": "Dimension", "name": "ResourceType"},
                    {"type": "Dimension", "name": "ResourceGroup"},
                ],
            },
        }
        return self._query(payload)
