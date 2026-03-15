# Longhorn Upgrade: v1.9.1 → v1.10.2

**Date Prepared:** February 9, 2026  
**Current Version:** v1.9.1  
**Target Version:** v1.10.2  
**Cluster:** k3s 9-node cluster (k3s-01 to k3s-06, lh-01 to lh-03)

## Executive Summary

Upgrading Longhorn to v1.10.2 to fix critical bugs:
- **Timestamp parsing error** causing replica state tracking failures
- **Volume attachment state desync** issues
- Multiple stability and performance improvements

**Estimated Downtime:** None (rolling upgrade)  
**Migration Duration:** ~30-45 minutes  
**Risk Level:** Medium

## Issues Fixed in v1.10.2

1. **Replica State Tracking Bug**: Fixes timestamp parsing error preventing proper replica health monitoring
2. **Volume Attachment Tracking**: Resolves state desync between Longhorn and Kubernetes
3. **Performance Improvements**: Better replica rebuild performance
4. **Stability**: Multiple bug fixes for edge cases causing corruption

## Prerequisites

### 1. Verify Current State
```bash
# Check current Longhorn version
kubectl get daemonset -n longhorn-system longhorn-manager -o jsonpath='{.spec.template.spec.containers[0].image}'
# Expected: rancher/mirrored-longhornio-longhorn-manager:v1.9.1

# Check all volumes are healthy
kubectl get volumes -n longhorn-system -o custom-columns=NAME:.metadata.name,STATE:.status.state,ROBUSTNESS:.status.robustness | grep -v "healthy\|detached"

# Verify no degraded volumes
kubectl get volumes -n longhorn-system | grep degraded
```

### 2. Backup Critical Data
```bash
# List all volumes with their sizes
kubectl get pvc -A -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,SIZE:.spec.resources.requests.storage,STORAGECLASS:.spec.storageClassName | grep longhorn

# Create snapshots for critical volumes (optional but recommended)
# Via Longhorn UI: http://longhorn.local/dashboard
# Or via CLI for automation
```

### 3. Verify Cluster Health
```bash
# Check all nodes are Ready
kubectl get nodes
# Expected: All 9 nodes Ready

# Check Longhorn storage nodes have sufficient space
kubectl get nodes.longhorn.io -n longhorn-system lh-01 lh-02 lh-03 -o yaml | grep -E '(storageAvailable|storageMaximum)'
# Current: ~200GB available on each node (18% usage)

# Verify no pod disruption budgets blocking upgrades
kubectl get pdb -n longhorn-system
```

### 4. Document Current State
```bash
# Export current Longhorn settings
kubectl get settings -n longhorn-system -o yaml > /home/matt/longhorn-settings-backup-$(date +%Y%m%d).yaml

# Save current replica configuration
kubectl get replicas -n longhorn-system -o yaml > /home/matt/longhorn-replicas-backup-$(date +%Y%m%d).yaml

# Export volume configurations
kubectl get volumes -n longhorn-system -o yaml > /home/matt/longhorn-volumes-backup-$(date +%Y%m%d).yaml
```

## Upgrade Procedure

### Method 1: Helm Upgrade (Recommended)

#### Step 1: Prepare Helm Repository
```bash
# Add/update Longhorn Helm repo
helm repo add longhorn https://charts.longhorn.io
helm repo update

# Check available versions
helm search repo longhorn/longhorn --versions | grep v1.10.2
```

#### Step 2: Get Current Helm Values
```bash
# Export current Helm values
helm get values longhorn -n longhorn-system > /home/matt/longhorn-helm-values-backup-$(date +%Y%m%d).yaml

# Review upgrade changes
helm diff upgrade longhorn longhorn/longhorn \
  --namespace longhorn-system \
  --version 1.10.2 \
  --values /home/matt/longhorn-helm-values-backup-$(date +%Y%m%d).yaml
```

#### Step 3: Perform Upgrade
```bash
# Upgrade Longhorn
helm upgrade longhorn longhorn/longhorn \
  --namespace longhorn-system \
  --version 1.10.2 \
  --values /home/matt/longhorn-helm-values-backup-$(date +%Y%m%d).yaml \
  --wait

# Monitor upgrade progress
watch kubectl get pods -n longhorn-system
```

### Method 2: kubectl Apply (Alternative)

#### Step 1: Download v1.10.2 Manifests
```bash
# Download Longhorn v1.10.2 deployment YAML
curl -sSfL https://raw.githubusercontent.com/longhorn/longhorn/v1.10.2/deploy/longhorn.yaml -o /home/matt/longhorn-v1.10.2.yaml
```

#### Step 2: Review and Apply
```bash
# Review changes (optional)
kubectl diff -f /home/matt/longhorn-v1.10.2.yaml

# Apply upgrade
kubectl apply -f /home/matt/longhorn-v1.10.2.yaml
```

## Post-Upgrade Verification

### 1. Verify Component Versions
```bash
# Check all DaemonSets and Deployments updated
kubectl get ds,deploy -n longhorn-system -o wide | grep longhorn

# Verify manager version
kubectl get daemonset longhorn-manager -n longhorn-system -o jsonpath='{.spec.template.spec.containers[0].image}'
# Expected: rancher/mirrored-longhornio-longhorn-manager:v1.10.2

# Check engine image
kubectl get deploy longhorn-driver-deployer -n longhorn-system -o jsonpath='{.spec.template.spec.containers[0].image}'
```

### 2. Check Volume Health
```bash
# All volumes should be healthy or attached
kubectl get volumes -n longhorn-system -o custom-columns=NAME:.metadata.name,STATE:.status.state,ROBUSTNESS:.status.robustness

# Verify no ERR replicas
kubectl get replicas -n longhorn-system | grep ERR || echo "No error replicas"

# Check events for any errors
kubectl get events -n longhorn-system --sort-by='.lastTimestamp' | tail -20
```

### 3. Test Volume Operations
```bash
# Create test PVC
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: longhorn-test-pvc
  namespace: default
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: longhorn
  resources:
    requests:
      storage: 1Gi
EOF

# Verify PVC bound
kubectl get pvc longhorn-test-pvc -n default
# Expected: STATUS Bound

# Test pod with volume
kubectl run longhorn-test --image=busybox --restart=Never --overrides='
{
  "apiVersion": "v1",
  "spec": {
    "containers": [{
      "name": "longhorn-test",
      "image": "busybox",
      "command": ["sh", "-c", "echo test > /data/test.txt && cat /data/test.txt && sleep 30"],
      "volumeMounts": [{
        "name": "data",
        "mountPath": "/data"
      }]
    }],
    "volumes": [{
      "name": "data",
      "persistentVolumeClaim": {
        "claimName": "longhorn-test-pvc"
      }
    }]
  }
}'

# Check test passed
kubectl logs longhorn-test
# Expected: test

# Cleanup
kubectl delete pod longhorn-test
kubectl delete pvc longhorn-test-pvc -n default
```

### 4. Monitor for Timestamp Errors
```bash
# Verify timestamp parsing bug is fixed
kubectl logs -n longhorn-system -l app=longhorn-manager --since=5m | grep "cannot parse timestamp"
# Expected: No output (bug fixed)
```

### 5. Verify Settings Preserved
```bash
# Check replica-soft-anti-affinity setting
kubectl get setting replica-soft-anti-affinity -n longhorn-system -o jsonpath='{.value}'
# Expected: true

# Verify storage reservations
kubectl get nodes.longhorn.io -n longhorn-system lh-01 lh-02 lh-03 -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.disks.default-disk-937973dab55add0f.storageReserved}{"\n"}{end}'
# Expected: 77515893964 for each node
```

## Rollback Procedure

If issues occur during upgrade:

### Quick Rollback (Helm)
```bash
# Roll back to previous version
helm rollback longhorn -n longhorn-system

# Monitor rollback
watch kubectl get pods -n longhorn-system
```

### Manual Rollback (kubectl)
```bash
# Reapply v1.9.1 manifests
curl -sSfL https://raw.githubusercontent.com/longhorn/longhorn/v1.9.1/deploy/longhorn.yaml -o /home/matt/longhorn-v1.9.1-rollback.yaml
kubectl apply -f /home/matt/longhorn-v1.9.1-rollback.yaml

# Restore settings if needed
kubectl apply -f /home/matt/longhorn-settings-backup-YYYYMMDD.yaml
```

### Restore from Backup
```bash
# If data corruption occurs (unlikely)
# Restore volumes from Longhorn backups via UI
# Or use kubectl to restore from S3/NFS backup target
```

## Known Issues and Mitigations

### Issue 1: Pod Scheduling During Upgrade
**Symptom:** Pods may be rescheduled during DaemonSet updates  
**Mitigation:** Upgrade runs as rolling update, only one node at a time  
**Action:** Monitor pod status, wait for stabilization between nodes

### Issue 2: Replica Rebuild After Upgrade
**Symptom:** Some replicas may rebuild after manager restart  
**Mitigation:** This is normal if replicas were in inconsistent state  
**Action:** Allow rebuilds to complete, monitor progress in UI

### Issue 3: Temporary Volume Detachment
**Symptom:** Volumes may briefly show as detached during manager pod restarts  
**Mitigation:** Volumes reattach automatically within 30-60 seconds  
**Action:** Wait for automatic reattachment, avoid manual intervention

## Maintenance Window Planning

### Recommended Schedule
- **Day:** Weekend (Saturday/Sunday) during low-traffic period
- **Time:** 2:00 AM - 4:00 AM local time
- **Duration:** 2-hour window (upgrade takes ~45 minutes)
- **Team:** On-call engineer available for rollback if needed

### Pre-Maintenance Checklist
- [ ] Notify stakeholders of maintenance window
- [ ] Verify backup completion
- [ ] Export current configurations
- [ ] Review rollback procedure
- [ ] Ensure monitoring/alerting active
- [ ] Have Longhorn UI access ready

### During Maintenance
- [ ] Execute upgrade procedure
- [ ] Monitor pod rollout progress
- [ ] Check for errors in logs
- [ ] Verify volume health
- [ ] Test sample workload

### Post-Maintenance
- [ ] Complete verification steps
- [ ] Monitor system for 24 hours
- [ ] Update documentation
- [ ] Notify stakeholders of completion
- [ ] Archive backup files (30-day retention)

## Monitoring and Alerting

### Key Metrics to Watch
```bash
# Watch volume count and health
watch 'kubectl get volumes -n longhorn-system | grep -c healthy'

# Monitor replica status
watch 'kubectl get replicas -n longhorn-system | tail -n +2 | wc -l'

# Check manager pod status
watch 'kubectl get pods -n longhorn-system -l app=longhorn-manager'

# Monitor storage capacity
watch 'kubectl get nodes.longhorn.io -n longhorn-system lh-01 lh-02 lh-03 -o custom-columns=NAME:.metadata.name,AVAILABLE:.status.diskStatus.default-disk-937973dab55add0f.storageAvailable'
```

### Expected Behavior
- **Pod Restarts:** Each longhorn-manager pod restarts once (9 total)
- **Duration per Node:** 3-5 minutes
- **Volume State:** Brief detached/attached transitions, then stable
- **Replica Health:** All healthy after ~15 minutes

## References

- **Longhorn v1.10.2 Release Notes:** https://github.com/longhorn/longhorn/releases/tag/v1.10.2
- **Upgrade Guide:** https://longhorn.io/docs/1.10.2/deploy/upgrade/
- **Known Issues:** https://github.com/longhorn/longhorn/issues
- **Backup Documentation:** https://longhorn.io/docs/1.10.2/snapshots-and-backups/

## Support Contacts

- **Longhorn Slack:** #longhorn on CNCF Slack
- **GitHub Issues:** https://github.com/longhorn/longhorn/issues
- **Community Forum:** https://forums.rancher.com/c/longhorn

## Change Log

| Date | Author | Changes |
|------|--------|---------|
| 2026-02-09 | GitHub Copilot | Initial upgrade plan created |

---

**Review Status:** ⚠️ Requires review before execution  
**Approval Required:** Yes  
**Tested on Staging:** No (production cluster)
