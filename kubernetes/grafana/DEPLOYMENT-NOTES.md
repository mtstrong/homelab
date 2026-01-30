# Monitoring Stack Deployment

This deployment sets up Prometheus, Grafana, and Loki for monitoring your homelab.

## Components

- **Prometheus**: Metrics collection and storage
- **Grafana**: Visualization and dashboards
- **Loki**: Log aggregation
- **Tautulli Exporter**: Exports Plex/Tautulli metrics to Prometheus

## Post-Deployment Steps

### 1. Get Tautulli API Key

1. Navigate to http://192.168.2.118:8181
2. Go to Settings → Web Interface → API
3. Copy the API key
4. Update the `tautulli-exporter` deployment:
   ```bash
   kubectl edit deployment tautulli-exporter -n tautulli
   ```
5. Replace `YOUR_TAUTULLI_API_KEY` with your actual API key

### 2. Access Grafana

1. Get the Grafana service IP:
   ```bash
   kubectl get svc -n grafana
   ```
2. Navigate to the Grafana URL
3. Default credentials: admin/admin (change on first login)
4. The Plex dashboard should be automatically available

### 3. Configure Additional Dashboards

The Plex dashboard will show:
- Current active streams
- Total bandwidth usage
- Stream count over time
- Top users (24h watch time)
- Transcoding sessions
- Library item counts

## Troubleshooting

If metrics aren't showing up:
1. Check if Tautulli exporter is running: `kubectl get pods -n tautulli`
2. Verify API key is correct
3. Check Prometheus targets: Navigate to Prometheus and check Status → Targets
