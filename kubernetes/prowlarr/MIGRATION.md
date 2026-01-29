# Prowlarr Migration from Docker to Kubernetes

## Pre-Migration

Current Prowlarr setup:
- Docker container: `lscr.io/linuxserver/prowlarr:2.0.4-nightly`
- Config location: `/home/matt/prowlarr` (~70MB)
- Port: 9696

## Migration Steps

### 1. Deploy Prowlarr to Kubernetes

The manifests are already created and managed by ArgoCD. After the PR is merged, ArgoCD will automatically deploy:
- Namespace: prowlarr
- PVC: prowlarr-config (5Gi Longhorn)
- Deployment: 1 replica with resource limits
- Service: ClusterIP on port 9696
- IngressRoute: prowlarr.tehmatt.com

### 2. Stop Docker Container

```bash
docker stop prowlarr
```

### 3. Copy Data to Kubernetes PVC

Get the pod name:
```bash
kubectl get pods -n prowlarr
```

Copy the config directory to the PVC:
```bash
# Using tar through kubectl exec
cd /home/matt
tar czf - -C prowlarr . | kubectl exec -n prowlarr -i <pod-name> -- tar xzf - -C /config
```

### 4. Verify Migration

Check pod logs:
```bash
kubectl logs -n prowlarr <pod-name> -f
```

Access Prowlarr:
- Internal: http://prowlarr.prowlarr.svc.cluster.local:9696
- External: https://prowlarr.tehmatt.com (after DNS configuration)

### 5. Test Functionality

- Verify indexers are configured
- Test search functionality
- Confirm apps (Sonarr, Radarr, etc.) can connect

### 6. Cleanup (After Verification)

```bash
# Remove Docker container
docker rm prowlarr

# Remove from docker-compose.yml
# Remove Docker data (backup first!)
# rm -rf /home/matt/prowlarr
```

## Rollback Plan

If issues occur:
```bash
# Scale down K8s deployment
kubectl scale deployment prowlarr -n prowlarr --replicas=0

# Start Docker container
docker start prowlarr
```

## Notes

- Database: prowlarr.db (~70MB) contains all indexer configurations
- Backups are in Backups/ directory
- Definitions/ contains indexer definitions
- Port 9696 remains the same for app connectivity
