# Azure FinOps Exporter 💰

A Prometheus exporter for Azure cost data that provides real-time FinOps visibility in a homelab Kubernetes cluster. Monitors Azure spending, tracks budgets, projects monthly costs, and sends budget alerts to Uptime Kuma.

## Architecture

```
┌─────────────────┐     ┌──────────────────────┐     ┌───────────────┐
│  Azure Cost     │────▶│  FinOps Exporter      │────▶│  Prometheus   │
│  Management API │     │  (Python, port 8080)  │     │               │
└─────────────────┘     │  /metrics             │     └───────┬───────┘
                        │  /health              │             │
                        │  /api/summary         │     ┌───────▼───────┐
                        └──────────┬────────────┘     │   Grafana     │
                                   │                  │   Dashboard   │
                        ┌──────────▼────────────┐     └───────────────┘
                        │  Uptime Kuma          │
                        │  (Push Monitor)       │     ┌───────────────┐
                        └───────────────────────┘     │   Homepage    │
                                                      │   Widget      │
                                                      └───────────────┘
```

## Features

- **Cost Metrics**: Month-to-date, daily, by-service, and by-resource cost breakdowns
- **Budget Tracking**: Configurable monthly budget with utilisation ratio
- **Cost Projection**: Linear projection of end-of-month spend
- **Budget Alerts**: Push notifications to Uptime Kuma when budget thresholds are exceeded
- **Grafana Dashboard**: Pre-built dashboard with cost trends, budget gauges, and resource tables
- **Homepage Widget**: Custom API integration showing live cost data
- **Prometheus Native**: Standard `/metrics` endpoint for seamless Prometheus scraping

## Prometheus Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `azure_cost_mtd_usd` | Gauge | Month-to-date total cost in USD |
| `azure_cost_daily_usd{date}` | Gauge | Daily cost in USD |
| `azure_cost_by_service_usd{service_name}` | Gauge | Cost by Azure service |
| `azure_cost_by_resource_usd{resource_name,resource_group,resource_type}` | Gauge | Cost by individual resource |
| `azure_cost_monthly_budget_usd` | Gauge | Configured monthly budget |
| `azure_cost_budget_utilisation_ratio` | Gauge | Current spend / budget (0-1+) |
| `azure_cost_projected_monthly_usd` | Gauge | Projected end-of-month cost |
| `azure_finops_last_update_timestamp` | Gauge | Last successful collection Unix timestamp |
| `azure_finops_collection_errors_total` | Counter | Total collection errors |

## API Endpoints

| Endpoint | Description |
|----------|-------------|
| `GET /metrics` | Prometheus metrics (text format) |
| `GET /health` | Health check (JSON) |
| `GET /api/summary` | Cost summary for homepage widget (JSON) |

### `/api/summary` Response

```json
{
  "mtd_cost_usd": 12.45,
  "monthly_budget_usd": 50.00,
  "budget_utilisation_pct": 24.9,
  "projected_monthly_usd": 38.20,
  "top_services": {
    "Container Instances": 10.50,
    "Virtual Network": 1.95
  },
  "last_updated": "2025-02-03T14:30:00Z"
}
```

## Prerequisites

### Azure Service Principal

Create a Service Principal with **Cost Management Reader** role:

```bash
# Create the SP
az ad sp create-for-rbac \
  --name "sp-finops-exporter" \
  --role "Cost Management Reader" \
  --scopes /subscriptions/<SUBSCRIPTION_ID>

# Note the output:
# {
#   "appId": "<CLIENT_ID>",
#   "password": "<CLIENT_SECRET>",
#   "tenant": "<TENANT_ID>"
# }
```

### Kubernetes Secret

Create the secret from the template:

```bash
# Copy and fill in the template
cp kubernetes/azure-finops/secret-template.yaml kubernetes/azure-finops/secret.yaml

# Edit with your actual values (base64 encoded)
echo -n "your-subscription-id" | base64
echo -n "your-tenant-id" | base64
echo -n "your-client-id" | base64
echo -n "your-client-secret" | base64

# Apply the secret
kubectl apply -f kubernetes/azure-finops/secret.yaml
```

Or create directly:

```bash
kubectl create secret generic azure-finops-credentials \
  --namespace azure-finops \
  --from-literal=AZURE_SUBSCRIPTION_ID=<sub-id> \
  --from-literal=AZURE_TENANT_ID=<tenant-id> \
  --from-literal=AZURE_CLIENT_ID=<client-id> \
  --from-literal=AZURE_CLIENT_SECRET=<client-secret>
```

## Configuration

All configuration is via environment variables (set in the ConfigMap):

| Variable | Default | Description |
|----------|---------|-------------|
| `AZURE_SUBSCRIPTION_ID` | — | Azure subscription to monitor (required) |
| `AZURE_TENANT_ID` | — | Azure AD tenant ID (required) |
| `AZURE_CLIENT_ID` | — | Service Principal app ID (required) |
| `AZURE_CLIENT_SECRET` | — | Service Principal password (required) |
| `MONTHLY_BUDGET_USD` | `50.00` | Monthly budget threshold in USD |
| `COLLECTION_INTERVAL_SECONDS` | `3600` | How often to query Azure (seconds) |
| `BUDGET_ALERT_THRESHOLD` | `0.8` | Alert when utilisation exceeds this ratio |
| `UPTIME_KUMA_PUSH_URL` | — | Uptime Kuma push monitor URL (optional) |
| `METRICS_PORT` | `8080` | HTTP server port |

## Deployment

### ArgoCD (Recommended)

The ArgoCD application definition at `argocd/azure-finops-application.yaml` will automatically sync the Kubernetes manifests. Simply:

1. Create the secret (see above)
2. Apply the ArgoCD app: `kubectl apply -f argocd/azure-finops-application.yaml`
3. ArgoCD handles the rest

### Manual

```bash
kubectl apply -f kubernetes/azure-finops/_namespace.yaml
kubectl apply -f kubernetes/azure-finops/configmap.yaml
kubectl apply -f kubernetes/azure-finops/secret.yaml  # Your filled-in secret
kubectl apply -f kubernetes/azure-finops/deployment.yaml
kubectl apply -f kubernetes/azure-finops/service.yaml
```

## Grafana Dashboard

A pre-built dashboard is included at `kubernetes/grafana/grafana-dashboard-finops.yaml`. It provides:

- **Budget Overview Row**: MTD Cost, Monthly Budget, Projected Cost, Budget Gauge, Collection Errors
- **Cost Trends Row**: Daily cost bar chart, Cost by Service donut chart
- **Resource Breakdown Row**: Sortable table of all resources with costs
- **Exporter Health Row**: Last collection time, exporter uptime

The dashboard is auto-provisioned via Grafana's file provisioning and mounted as a ConfigMap.

## Budget Alerts

When `UPTIME_KUMA_PUSH_URL` is configured, the exporter pushes status to an Uptime Kuma push monitor:

- **Status OK** (`up`): Budget utilisation below threshold
- **Status Warning** (`down`): Utilisation exceeds `BUDGET_ALERT_THRESHOLD` (default 80%)
- **Status Critical** (`down`): Spend exceeds budget (100%+)

### Setting Up Uptime Kuma Push Monitor

1. In Uptime Kuma, create a new **Push** type monitor
2. Set the push interval to match `COLLECTION_INTERVAL_SECONDS`
3. Copy the push URL and set it as `UPTIME_KUMA_PUSH_URL`

## Local Development

```bash
cd apps/azure-finops-exporter

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Set environment variables
export AZURE_SUBSCRIPTION_ID="..."
export AZURE_TENANT_ID="..."
export AZURE_CLIENT_ID="..."
export AZURE_CLIENT_SECRET="..."
export MONTHLY_BUDGET_USD="50.00"
export COLLECTION_INTERVAL_SECONDS="300"

# Run
python src/main.py
```

## CI/CD

The GitHub Actions workflow (`.github/workflows/azure-finops-build.yml`) handles:

1. **Lint & Validate**: flake8, mypy, hadolint
2. **Build & Push**: Multi-arch Docker image to `ghcr.io/mtstrong/azure-finops-exporter`
3. **Tags**: `latest`, git SHA, timestamp

Triggered on pushes to `main` that modify `apps/azure-finops-exporter/**`.

## Project Structure

```
apps/azure-finops-exporter/
├── Dockerfile
├── README.md
├── requirements.txt
└── src/
    ├── main.py              # Entrypoint, HTTP server, Prometheus metrics
    ├── config.py            # Environment variable configuration
    ├── cost_collector.py    # Azure Cost Management API client
    └── budget_alerter.py    # Uptime Kuma push alerting

kubernetes/azure-finops/
├── kustomization.yaml
├── _namespace.yaml
├── configmap.yaml
├── secret-template.yaml
├── deployment.yaml
└── service.yaml

kubernetes/grafana/
└── grafana-dashboard-finops.yaml   # Grafana dashboard ConfigMap

argocd/
└── azure-finops-application.yaml   # ArgoCD app definition

.github/workflows/
└── azure-finops-build.yml          # CI/CD pipeline
```

## Tech Stack

- **Language**: Python 3.11
- **Azure SDK**: `azure-identity` for Service Principal auth
- **Metrics**: `prometheus-client` for Prometheus exposition
- **HTTP**: Built-in `http.server` (zero extra dependencies)
- **Container**: Multi-arch Docker image (amd64/arm64)
- **Orchestration**: Kubernetes (k3s) + ArgoCD + Kustomize
- **Monitoring**: Prometheus → Grafana → Homepage
- **Alerting**: Uptime Kuma push monitors
