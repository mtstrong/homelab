"""Azure FinOps Exporter — Prometheus metrics for Azure cost data.

Exposes Azure Cost Management data as Prometheus metrics and provides
a JSON summary endpoint for the Homepage dashboard widget.
"""

import calendar
import json
import logging
import threading
import time
from datetime import datetime
from http.server import BaseHTTPRequestHandler, HTTPServer

from prometheus_client import CONTENT_TYPE_LATEST, Gauge, generate_latest

from budget_alerter import BudgetAlerter
from config import Config
from cost_collector import AzureCostCollector

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("azure-finops-exporter")

# ---------------------------------------------------------------------------
# Prometheus metrics
# ---------------------------------------------------------------------------
MONTHLY_COST = Gauge("azure_cost_mtd_usd", "Month-to-date Azure cost in USD")
DAILY_COST = Gauge("azure_cost_daily_usd", "Daily Azure cost in USD", ["date"])
SERVICE_COST = Gauge("azure_cost_by_service_usd", "Cost by Azure service MTD", ["service_name"])
RESOURCE_COST = Gauge(
    "azure_cost_by_resource_usd",
    "Cost by Azure resource MTD",
    ["resource_name", "resource_group", "resource_type"],
)
BUDGET_AMOUNT = Gauge("azure_cost_monthly_budget_usd", "Monthly budget amount in USD")
BUDGET_UTILISATION = Gauge("azure_cost_budget_utilisation_ratio", "Budget utilisation (0‑1+)")
PROJECTED_COST = Gauge("azure_cost_projected_monthly_usd", "Projected end-of-month cost in USD")
LAST_UPDATE = Gauge("azure_finops_last_update_timestamp", "Unix timestamp of last successful collection")
COLLECTION_ERRORS = Gauge("azure_finops_collection_errors_total", "Total number of collection errors")

# In‑memory summary for the /api/summary JSON endpoint
_summary: dict = {}


# ---------------------------------------------------------------------------
# Collection logic
# ---------------------------------------------------------------------------
def _days_in_month(dt: datetime) -> int:
    return calendar.monthrange(dt.year, dt.month)[1]


def collect_metrics(
    collector: AzureCostCollector,
    alerter: BudgetAlerter,
    config: Config,
) -> None:
    """Query Azure Cost Management and update all Prometheus metrics."""
    global _summary
    try:
        logger.info("Collecting Azure cost data …")

        # -- Month‑to‑date by service & resource group (daily) -----------
        monthly_data = collector.get_monthly_costs_by_service()
        rows = monthly_data.get("properties", {}).get("rows", [])

        mtd_total = 0.0
        service_costs: dict[str, float] = {}
        daily_costs: dict[str, float] = {}

        for row in rows:
            cost = float(row[0])
            date_raw = row[1]  # int YYYYMMDD or str
            service = str(row[2]) if len(row) > 2 else "Unknown"

            mtd_total += cost
            service_costs[service] = service_costs.get(service, 0.0) + cost

            date_str = str(date_raw)[:8]  # "20260210"
            daily_costs[date_str] = daily_costs.get(date_str, 0.0) + cost

        MONTHLY_COST.set(round(mtd_total, 4))
        BUDGET_AMOUNT.set(config.MONTHLY_BUDGET_USD)

        utilisation = mtd_total / config.MONTHLY_BUDGET_USD if config.MONTHLY_BUDGET_USD > 0 else 0.0
        BUDGET_UTILISATION.set(round(utilisation, 4))

        now = datetime.utcnow()
        day_of_month = now.day
        dim = _days_in_month(now)
        projected = (mtd_total / day_of_month) * dim if day_of_month > 0 else 0.0
        PROJECTED_COST.set(round(projected, 4))

        for svc, cost in service_costs.items():
            SERVICE_COST.labels(service_name=svc).set(round(cost, 4))

        for date, cost in sorted(daily_costs.items()):
            DAILY_COST.labels(date=date).set(round(cost, 4))

        # -- Per‑resource costs ------------------------------------------
        try:
            res_data = collector.get_resource_costs()
            res_rows = res_data.get("properties", {}).get("rows", [])
            resource_list = []
            for row in res_rows:
                cost = float(row[0])
                resource_id = str(row[1]) if len(row) > 1 else "unknown"
                resource_type = str(row[2]) if len(row) > 2 else "unknown"
                resource_group = str(row[3]) if len(row) > 3 else "unknown"
                resource_name = resource_id.rsplit("/", 1)[-1] if "/" in resource_id else resource_id
                type_short = resource_type.rsplit("/", 1)[-1] if "/" in resource_type else resource_type
                RESOURCE_COST.labels(
                    resource_name=resource_name,
                    resource_group=resource_group,
                    resource_type=type_short,
                ).set(round(cost, 4))
                resource_list.append(
                    {"name": resource_name, "group": resource_group, "type": type_short, "cost": round(cost, 2)}
                )
        except Exception as exc:
            logger.warning("Failed to collect resource‑level costs: %s", exc)
            resource_list = []

        LAST_UPDATE.set(time.time())

        logger.info(
            "Collection complete — MTD $%.2f | Budget %.0f%% | Projected $%.2f",
            mtd_total,
            utilisation * 100,
            projected,
        )

        # Update in‑memory summary for JSON endpoint
        _summary = {
            "mtd_cost_usd": round(mtd_total, 2),
            "monthly_budget_usd": config.MONTHLY_BUDGET_USD,
            "budget_utilisation_pct": round(utilisation * 100, 1),
            "projected_monthly_usd": round(projected, 2),
            "top_services": sorted(
                [{"service": k, "cost": round(v, 2)} for k, v in service_costs.items()],
                key=lambda x: x["cost"],
                reverse=True,
            )[:10],
            "resources": sorted(resource_list, key=lambda x: x["cost"], reverse=True),
            "last_updated": datetime.utcnow().isoformat() + "Z",
        }

        # Budget alerting
        alerter.check_and_alert(mtd_total, utilisation, projected)

    except Exception as exc:
        logger.error("Collection failed: %s", exc)
        COLLECTION_ERRORS.inc()


def _collection_loop(
    collector: AzureCostCollector,
    alerter: BudgetAlerter,
    config: Config,
) -> None:
    """Background thread that collects metrics on a schedule."""
    while True:
        collect_metrics(collector, alerter, config)
        time.sleep(config.COLLECTION_INTERVAL_SECONDS)


# ---------------------------------------------------------------------------
# HTTP server (Prometheus /metrics + JSON /api/summary + /health)
# ---------------------------------------------------------------------------
class _Handler(BaseHTTPRequestHandler):
    """Handles /metrics, /health, and /api/summary."""

    def do_GET(self) -> None:  # noqa: N802
        if self.path == "/metrics":
            body = generate_latest()
            self.send_response(200)
            self.send_header("Content-Type", CONTENT_TYPE_LATEST)
            self.end_headers()
            self.wfile.write(body)

        elif self.path == "/health":
            self._json_response(200, {"status": "ok"})

        elif self.path == "/api/summary":
            self._json_response(200, _summary or {"status": "collecting"})

        else:
            self.send_response(404)
            self.end_headers()

    def _json_response(self, code: int, data: dict) -> None:
        body = json.dumps(data).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, fmt: str, *args: object) -> None:  # noqa: ARG002
        """Suppress per‑request access logs."""


# ---------------------------------------------------------------------------
# Entrypoint
# ---------------------------------------------------------------------------
def main() -> None:
    config = Config()

    required = {
        "AZURE_SUBSCRIPTION_ID": config.AZURE_SUBSCRIPTION_ID,
        "AZURE_TENANT_ID": config.AZURE_TENANT_ID,
        "AZURE_CLIENT_ID": config.AZURE_CLIENT_ID,
        "AZURE_CLIENT_SECRET": config.AZURE_CLIENT_SECRET,
    }
    missing = [k for k, v in required.items() if not v]
    if missing:
        logger.error("Missing required environment variables: %s", ", ".join(missing))
        return

    collector = AzureCostCollector(config)
    alerter = BudgetAlerter(config)

    # Seed the budget gauge immediately
    BUDGET_AMOUNT.set(config.MONTHLY_BUDGET_USD)

    # Start background collection thread
    logger.info(
        "Starting collection loop (interval %ds, budget $%.2f)",
        config.COLLECTION_INTERVAL_SECONDS,
        config.MONTHLY_BUDGET_USD,
    )
    thread = threading.Thread(
        target=_collection_loop,
        args=(collector, alerter, config),
        daemon=True,
    )
    thread.start()

    # Start HTTP server (blocking)
    server = HTTPServer(("0.0.0.0", config.METRICS_PORT), _Handler)
    logger.info("Serving metrics on :%d/metrics", config.METRICS_PORT)
    logger.info("JSON summary on :%d/api/summary", config.METRICS_PORT)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        logger.info("Shutting down")
        server.shutdown()


if __name__ == "__main__":
    main()
