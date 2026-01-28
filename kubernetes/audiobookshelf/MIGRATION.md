# AudioBookshelf Docker to Kubernetes Migration Guide

## Overview
This guide will help you migrate AudioBookshelf from Docker to Kubernetes while preserving all your data.

## Current Setup
- **Docker Image**: `ghcr.io/advplyr/audiobookshelf:2.28.0`
- **Port**: 13378 → 80
- **Domain**: `abs.tehmatt.com`

### Docker Volumes
- `/home/matt/audiobookshelf` → `/config` and `/metadata`
- `audiobooks` volume → `/audiobooks`
- `podcasts` volume → `/podcasts`  
- `audiobook-uploads` volume → `/uploads`

## Kubernetes Resources Created

### Location
All manifests are in: `code/homelab/kubernetes/audiobookshelf/`

### Resources
1. **namespace.yaml** - Creates `audiobookshelf` namespace
2. **pvc.yaml** - 3 PersistentVolumeClaims (Longhorn):
   - `audiobookshelf-config` (5Gi)
   - `audiobookshelf-metadata` (10Gi)
   - `audiobookshelf-uploads` (10Gi)
3. **deployment.yaml** - Deployment with PVC and NFS mounts:
   - PVCs: config, metadata, uploads
   - NFS Mounts: audiobooks (`/mnt/TrueNAS/audiobooks`), podcasts (`/mnt/TrueNAS/podcasts`)
4. **service.yaml** - ClusterIP service on port 80
5. **ingress.yaml** - Traefik IngressRoute for `abs.tehmatt.com`
6. **argocd/apps/audiobookshelf.yaml** - ArgoCD Application

### Git Branch
Branch: `feature/audiobookshelf-k8s-migration`

## Migration Steps

### Phase 1: Prepare Kubernetes (Before Data Migration)

1. **Push the branch to GitHub**:
   ```bash
   cd /home/matt/code/homelab
   git push -u origin feature/audiobookshelf-k8s-migration
   ```

2. **Create the PVCs** (but don't deploy the app yet):
   ```bash
   kubectl apply -f kubernetes/audiobookshelf/namespace.yaml
   kubectl apply -f kubernetes/audiobookshelf/pvc.yaml
   ```

3. **Wait for PVCs to be bound**:
   ```bash
   kubectl get pvc -n audiobookshelf
   ```

### Phase 2: Data Migration (Following Jim's Garage Method)

4. **Ensure TrueNAS NFS shares exist**:
   - Verify `/mnt/TrueNAS/audiobooks` and `/mnt/TrueNAS/podcasts` exist on TrueNAS (192.168.1.38)
   - If they don't exist, create them on TrueNAS and configure NFS exports

5. **Copy audiobooks and podcasts to TrueNAS** (if not already there):
   ```bash
   # From Docker host, copy to TrueNAS shares
   rsync -avxHAX /var/lib/docker/volumes/audiobooks/_data/ /path/to/truenas/mount/audiobooks/
   rsync -avxHAX /var/lib/docker/volumes/podcasts/_data/ /path/to/truenas/mount/podcasts/
   ```
   
   Or mount TrueNAS shares directly and copy:
   ```bash
   sudo mkdir -p /mnt/temp/audiobooks /mnt/temp/podcasts
   sudo mount -t nfs 192.168.1.38:/mnt/TrueNAS/audiobooks /mnt/temp/audiobooks
   sudo mount -t nfs 192.168.1.38:/mnt/TrueNAS/podcasts /mnt/temp/podcasts
   sudo rsync -avxHAX /var/lib/docker/volumes/audiobooks/_data/ /mnt/temp/audiobooks/
   sudo rsync -avxHAX /var/lib/docker/volumes/podcasts/_data/ /mnt/temp/podcasts/
   sudo umount /mnt/temp/audiobooks /mnt/temp/podcasts
   ```

6. **Identify which node has the Longhorn volumes**:
   ```bash
   kubectl get pv | grep audiobookshelf
   ```

7. **Stop the Docker container** (to prevent data changes during migration):
   ```bash
   docker stop audiobookshelf
   ```

8. **On a worker node, create a temporary mount point**:
   ```bash
   sudo mkdir /tmp/abs-migration
   ```

9. **Find the Longhorn volume devices**:
   ```bash
   sudo fdisk -l | grep longhorn
   ```

10. **Mount each Longhorn volume and copy data** (only config, metadata, uploads):

   For **config** volume:
   ```bash
   # Find the device (e.g., /dev/sdX)
   sudo mount /dev/sdX /tmp/abs-migration
   sudo rsync -avxHAX /home/matt/audiobookshelf/ /tmp/abs-migration/
   sudo umount /tmp/abs-migration
   ```

   For **metadata** volume:
   ```bash
   sudo mount /dev/sdY /tmp/abs-migration
   sudo rsync -avxHAX /home/matt/audiobookshelf/ /tmp/abs-migration/
   sudo umount /tmp/abs-migration
   ```

   For **uploads** volume:
   ```bash
   sudo mount /dev/sdZ /tmp/abs-migration
   sudo rsync -avxHAX /var/lib/docker/volumes/audiobook-uploads/_data/ /tmp/abs-migration/
   sudo umount /tmp/abs-migration
   ```

### Phase 3: Deploy to Kubernetes

11. **Apply the ArgoCD Application**:
    ```bash
    kubectl apply -f kubernetes/argocd/apps/audiobookshelf.yaml
    ```

    Or manually apply all manifests:
    ```bash
    kubectl apply -f kubernetes/audiobookshelf/
    ```

12. **Check the deployment**:
    ```bash
    kubectl get pods -n audiobookshelf
    kubectl logs -n audiobookshelf -l app=audiobookshelf
    ```

13. **Verify the ingress**:
    ```bash
    kubectl get ingressroute -n audiobookshelf
    ```

14. **Test the application**:
    - Navigate to `https://abs.tehmatt.com`
    - Verify all your audiobooks and data are present

### Phase 4: Cleanup (After Successful Migration)

15. **Remove Docker container and volumes** (ONLY after confirming K8s works):
    ```bash
    docker rm audiobookshelf
    docker volume rm audiobooks podcasts audiobook-uploads
    rm -rf /home/matt/audiobookshelf
    ```

16. **Merge the feature branch**:
    ```bash
    cd /home/matt/code/homelab
    git checkout main
    git merge feature/audiobookshelf-k8s-migration
    git push
    ```

## Troubleshooting

### Pod won't start
```bash
kubectl describe pod -n audiobookshelf -l app=audiobookshelf
kubectl logs -n audiobookshelf -l app=audiobookshelf
```

### PVC stuck in Pending
```bash
kubectl describe pvc -n audiobookshelf
# Check Longhorn UI for volume status
```

### Can't access via ingress
```bash
kubectl get ingressroute -n audiobookshelf -o yaml
kubectl logs -n traefik -l app.kubernetes.io/name=traefik
```

### Need to rollback
```bash
# Delete the K8s deployment
kubectl delete -f kubernetes/audiobookshelf/

# Start Docker container again
docker start audiobookshelf
```

## Notes

- **NFS Mounts**: Audiobooks and podcasts are stored on TrueNAS (192.168.1.38) via NFS mounts at `/mnt/TrueNAS/audiobooks` and `/mnt/TrueNAS/podcasts`
- **PVCs**: Only config, metadata, and uploads use Longhorn persistent volumes
- The migration preserves all data: library, metadata, users, settings
- Downtime required: Stop Docker → Migrate Data → Start K8s (estimate: 15-30 min for PVC data only)
- The Longhorn volumes will be automatically created when you apply the PVCs
- ArgoCD will auto-sync changes from the git repo after initial deployment
- Storage sizes can be adjusted in `pvc.yaml` if needed

## References
- Jim's Garage Video: https://www.youtube.com/watch?v=9VV7cKeH3Ro
- Jim's Garage GitHub: https://github.com/JamesTurland/JimsGarage/tree/main/Kubernetes/Docker-Kubernetes-Data-Migration
