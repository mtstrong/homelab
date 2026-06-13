# TrueNAS Config to Longhorn Migration

This tracks the remaining Kubernetes applications that still keep application config on TrueNAS NFS instead of Longhorn PVCs.

## Current State

Live cluster checks from 2026-06-12:

- Longhorn available capacity: 547.08 GiB
- Longhorn scheduled capacity: 251 GiB
- Longhorn maximum capacity: 833.58 GiB
- Existing Longhorn PVC requests: 97 GiB across 18 PVCs

Prepared PVCs in this repo for the remaining config migrations:

| App | Namespace | Current TrueNAS path | Measured size | New PVC | StorageClass | Requested size | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Overseerr | `overseerr` | `/mnt/TrueNAS/proxmox/config/overseerr` | `2.9M` | `overseerr` | `longhorn` | `1Gi` | Migrated live on `2026-06-12` |
| Calibre | `calibre` | `/mnt/TrueNAS/proxmox/config/calibre` | `35M` | `calibre-config` | `longhorn` | `5Gi` | Migrated live on `2026-06-12` |
| SABnzbd | `sabnzbd` | `/mnt/TrueNAS/proxmox/config/sabnzbd` | `9.1M` | `sabnzbd-config` | `longhorn` | `5Gi` | Migrated live on `2026-06-12` |
| Mealie | `mealie` | `/mnt/TrueNAS/proxmox/config/mealie` | `1.1M` | `mealie-data` | `longhorn` | `5Gi` | Migrated live on `2026-06-12` |

If all four PVCs are created as sized above, total requested Longhorn capacity increases by 16 GiB, taking the cluster from 97 GiB to 113 GiB requested. Based on current free capacity, aggregate Longhorn space is not the limiting factor for these config migrations.

The measured source usage is far below the planned PVC sizes, so none of these four apps need a PVC size increase before cutover.

All remaining Kubernetes application config previously stored on TrueNAS NFS has now been migrated to Longhorn.

## Important GitOps Note

Overseerr and Mealie were both migrated live and their ArgoCD applications were returned to automated sync after the updated manifests were pushed to the tracked remote branch.

## Per-App Validation

Before cutover, verify the actual source usage for each app from TrueNAS or from a Linux host that mounts the share:

```bash
du -sh /mnt/TrueNAS/proxmox/config/overseerr
du -sh /mnt/TrueNAS/proxmox/config/calibre
du -sh /mnt/TrueNAS/proxmox/config/sabnzbd
du -sh /mnt/TrueNAS/proxmox/config/mealie
```

Use this rule before migrating an app:

- Keep at least 25% headroom above the measured size.
- If the directory is over 75% of the planned PVC size, increase the PVC before cutover.
- For SQLite-backed apps, stop writes before the final copy.

## Safe Migration Procedure

Do not switch a deployment from NFS to Longhorn until the PVC exists and the data has been copied.

### 1. Create the PVC

```bash
kubectl apply -f kubernetes/<app>/pvc.yaml
kubectl get pvc -n <namespace>
```

### 2. Scale the app down

```bash
kubectl scale deployment <deployment> -n <namespace> --replicas=0
kubectl get pods -n <namespace>
```

### 3. Copy data with a temporary pod

Create a temporary pod that mounts both the old NFS path and the new PVC, then run `rsync` inside it.

Example pod manifest:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: migration-copy
  namespace: <namespace>
spec:
  restartPolicy: Never
  containers:
  - name: copy
    image: alpine:3.20
    command: ["/bin/sh", "-c", "sleep 3600"]
    volumeMounts:
    - name: source
      mountPath: /source
    - name: target
      mountPath: /target
  volumes:
  - name: source
    nfs:
      server: 192.168.1.70
      path: <truenas-path>
  - name: target
    persistentVolumeClaim:
      claimName: <pvc-name>
```

Then copy the data:

```bash
kubectl apply -f migration-copy.yaml
kubectl exec -n <namespace> migration-copy -- sh -c "apk add --no-cache rsync"
kubectl exec -n <namespace> migration-copy -- sh -c "rsync -aHAX --delete /source/ /target/"
kubectl exec -n <namespace> migration-copy -- sh -c "du -sh /target"
kubectl delete pod -n <namespace> migration-copy
```

### 4. Switch the deployment

Update the deployment so the config mount uses the new PVC instead of NFS, then apply the manifest and scale back up.

### 5. Verify the app

- Pod starts cleanly
- UI loads
- Existing users, settings, and backups are present
- Logs do not show first-run initialization

## App Notes

### Overseerr

- Existing repo already had an unused backup PVC manifest.
- Start here because the config footprint should be the smallest of the remaining apps.

### Mealie

- Stores its full app data under `/app/data`.
- Treat this as stateful application data, not just loose config files.

### Calibre

- Only migrate `/config` to Longhorn.
- Keep the `/books` mount on TrueNAS unless you explicitly want the library on cluster storage.

### SABnzbd

- Only migrate `/config` to Longhorn.
- Keep `/downloads` on NAS storage.
- Schedule this after the queue is idle to avoid copying changing state.