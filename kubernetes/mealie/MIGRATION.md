# Mealie Docker to Kubernetes Migration Guide

## Overview
This guide documents the migration of Mealie from Docker Compose to Kubernetes.

## Current Docker Setup
- **Image**: ghcr.io/mealie-recipes/mealie:v3.0.2
- **Port**: 9925:9000 (Docker host:container)
- **Domain**: https://mealie.tehmatt.com
- **Data Location**: /home/matt/mealie (2.3MB)
- **Memory Limit**: 1000M

## Kubernetes Architecture

### Storage
- **PVC**: mealie-data (5Gi, Longhorn) - All application data
  - Database (mealie.db)
  - Recipes
  - User data
  - Backups

### Networking
- **Service**: ClusterIP on port 9000
- **Ingress**: Traefik IngressRoute for mealie.tehmatt.com with Let's Encrypt

### Configuration
All environment variables preserved:
- ALLOW_SIGNUP=true
- PUID=1000, PGID=1000
- TZ=America/Chicago
- MAX_WORKERS=1
- WEB_CONCURRENCY=1
- BASE_URL=https://mealie.tehmatt.com

## Migration Steps

### 1. Create Kubernetes Resources
```bash
# Create namespace and PVC
kubectl apply -f kubernetes/mealie/namespace.yaml
kubectl apply -f kubernetes/mealie/pvc.yaml

# Wait for PVC to be bound
kubectl get pvc -n mealie
```

### 2. Deploy Application
```bash
# Deploy Mealie
kubectl apply -f kubernetes/mealie/deployment.yaml
kubectl apply -f kubernetes/mealie/service.yaml
kubectl apply -f kubernetes/mealie/ingress.yaml

# Check deployment status
kubectl get pods -n mealie
```

### 3. Copy Data from Docker
```bash
# Get pod name
POD=$(kubectl get pod -n mealie -l app=mealie -o jsonpath='{.items[0].metadata.name}')

# Copy data directory contents
kubectl cp /home/matt/mealie/ mealie/$POD:/app/data/

# Verify data
kubectl exec -n mealie $POD -- ls -la /app/data/
```

### 4. Restart Pod
```bash
# Restart to load existing data
kubectl delete pod -n mealie -l app=mealie

# Wait for pod to be ready
kubectl wait --for=condition=ready pod -l app=mealie -n mealie --timeout=120s
```

### 5. Verify Application
- Access https://mealie.tehmatt.com
- Verify recipes and users are present
- Check logs: `kubectl logs -n mealie -l app=mealie`

### 6. Stop Docker Container
```bash
# Only after verifying Kubernetes deployment works
docker stop mealie
docker rm mealie
```

### 7. Add to ArgoCD
```bash
kubectl apply -f kubernetes/argocd/apps/mealie.yaml
```

## Rollback Plan
If issues occur:
```bash
# Delete Kubernetes resources
kubectl delete -f kubernetes/mealie/

# Restart Docker container
docker start mealie
```

## Notes
- Database file is mealie.db (SQLite)
- All data is stored in /app/data within the container
- Health checks use /api/app/about endpoint
- Application runs on port 9000 internally
