"""Budget alerting via Uptime Kuma push monitors.

Pushes budget utilisation status to an Uptime Kuma push-type monitor so
that budget breaches surface as "down" in the monitoring dashboard.
"""

import logging
import time

import requests

from config import Config

logger = logging.getLogger(__name__)


class BudgetAlerter:
    """Sends budget status to Uptime Kuma push monitor."""

    def __init__(self, config: Config) -> None:
        self.config = config
        self._last_alert_ts: float = 0
        self._cooldown = 300  # seconds between pushes

    def check_and_alert(
        self,
        mtd_cost: float,
        utilisation: float,
        projected: float,
    ) -> None:
        """Evaluate budget thresholds and push status to Uptime Kuma."""
        if not self.config.UPTIME_KUMA_PUSH_URL:
            return

        now = time.time()
        if now - self._last_alert_ts < self._cooldown:
            return

        budget = self.config.MONTHLY_BUDGET_USD

        if utilisation >= 1.0:
            status = "down"
            msg = (
                f"OVER BUDGET: ${mtd_cost:.2f}/${budget:.2f} "
                f"({utilisation * 100:.0f}%) | Projected: ${projected:.2f}"
            )
        elif utilisation >= self.config.BUDGET_ALERT_THRESHOLD:
            status = "down"
            msg = (
                f"Budget warning: ${mtd_cost:.2f}/${budget:.2f} "
                f"({utilisation * 100:.0f}%) | Projected: ${projected:.2f}"
            )
        else:
            status = "up"
            msg = (
                f"${mtd_cost:.2f}/${budget:.2f} "
                f"({utilisation * 100:.0f}%) | Projected: ${projected:.2f}"
            )

        try:
            resp = requests.get(
                self.config.UPTIME_KUMA_PUSH_URL,
                params={"status": status, "msg": msg, "ping": ""},
                timeout=10,
            )
            if resp.status_code == 200:
                logger.info("Pushed budget status [%s]: %s", status, msg)
            else:
                logger.warning("Uptime Kuma push returned %d", resp.status_code)
            self._last_alert_ts = now
        except Exception as exc:
            logger.error("Failed to push to Uptime Kuma: %s", exc)
