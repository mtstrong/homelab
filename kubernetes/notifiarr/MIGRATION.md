# Notifiarr Docker to Kubernetes Migration Guide

## Overview
This guide documents the migration of Notifiarr from Docker Compose to Kubernetes.

## Current Docker Setup
- **Image**: golift/notifiarr:0.8.3
- **Port**: 5454
- **Domain**: notifiarr.tehmatt.com (assumed)
- **Data Location**: /home/matt/notifiarr (68K)
- **Key Files**: notifiarr.conf, backups/

## Kubernetes Architecture

### Storage
- **PVC**: notifiarr-config (1Gi, Longhorn) - Configuration and backups

### Networking
- **Service**: ClusterIP on port 5454
- **Ingress**: Traefik IngressRoute for notifiarr.tehmatt.com

### Special Mounts
- `/etc/machine-id` - Host machine ID (read-only)
- `/var/run/utmp` - System uptime data (read-only)

## Migration Steps

### 1. Create Kubernetes Resources
```bash
# Create namespace and PVC
kubectl apply -f kubernetes/notifiarr/namespace.yaml
kubectl apply -f kubernetes/notifiarr/pvc.yaml

# Wait for PVC to be bound
kubectl get pvc -n notifiarr
```

### 2. Deploy Application
```bash
# Deploy Notifiarr
kubectl apply -f kubernetes/notifiarr/middleware.yaml
kubectl apply -f kubernetes/notifiarr/deployment.yaml
kubectl apply -f kubernetes/notifiarr/service.yaml
kubectl apply -f kubernetes/notifiarr/ingress.yaml

# Check deployment status
kubectl get pods -n notifiarr
```

### 3. Copy Configuration from Docker
```bash
# Stop Docker container
docker stop notifiarr

# Get pod name
POD=$(kubectl get pod -n notifiarr -l app=notifiarr -o jsonpath='{.items[0].metadata.name}')

# Copy config directory contents
kubectl cp /home/matt/notifiarr/ notifiarr/$POD:/config/

# Verify data
kubectl exec -n notifiarr $POD -- ls -la /config/
```

### 4. Restart Pod
```bash
# Restart to load existing configuration
kubectl delete pod -n notifiarr -l app=notifiarr

# Wait for pod to be ready
kubectl wait --for=condition=ready pod -l app=notifiarr -n notifiarr --timeout=120s
```

### 5. Verify Application
- Access https://notifiarr.tehmatt.com
- Verify integrations are working
- Check logs: `kubectl logs -n notifiarr -l app=notifiarr`

### 6. Clean Up Docker
```bash
# Only after verifying Kubernetes deployment works
docker rm notifiarr
rm -rf /home/matt/notifiarr
```

### 7. Add to ArgoCD
```bash
# Update kustomization.yaml to include notifiarr
kubectl apply -f kubernetes/argocd/apps/notifiarr.yaml
```

## Rollback Plan
If issues occur:
```bash
# Delete Kubernetes resources
kubectl delete -f kubernetes/notifiarr/

# Restart Docker container
docker start notifiarr
```

## Notes
- Configuration file is notifiarr.conf
- Requires host machine-id and utmp for system monitoring
- Small data footprint (68K config)
- Port 5454 for web interface
- Supports various integrations (Sonarr, Radarr, etc.)
