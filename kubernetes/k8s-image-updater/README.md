# K8s Image Updater

Automated Kubernetes image updater that scans the cluster weekly for container image updates and creates GitHub Pull Requests with updated manifests.

## Overview

This application runs as a Kubernetes CronJob and:
- Scans all deployments in the cluster every Monday at 9 AM UTC
- Checks DockerHub, LSCR, and GHCR for newer image versions
- Analyzes semantic versioning to find compatible updates
- Creates GitHub PRs with detailed changelogs and update information

## Configuration

The application is configured via ConfigMap in [configmap.yaml](configmap.yaml):

- **GitHub Settings**: Points to `mtstrong/homelab` repository
- **Manifest Paths**: Scans `/workspace/kubernetes/` for deployment files
- **Update Policy**: Allows minor and patch updates, blocks major updates
- **Registries**: Supports DockerHub, LSCR, and GHCR

## Secret Setup

Before deploying, update the GitHub token in [secret.yaml](secret.yaml):

```bash
# Generate a GitHub Personal Access Token with 'repo' scope
# Then update the secret:
kubectl create secret generic github-token \
  --from-literal=token=YOUR_GITHUB_TOKEN \
  --namespace=image-updater \
  --dry-run=client -o yaml | kubectl apply -f -
```

Or manually edit the secret file and apply it.

## Deployment

This application is managed by ArgoCD. The application definition is in [../../argocd/k8s-image-updater-application.yaml](../../argocd/k8s-image-updater-application.yaml).

### Deploy via ArgoCD

```bash
kubectl apply -f ../../argocd/k8s-image-updater-application.yaml
```

ArgoCD will automatically:
- Create the `image-updater` namespace
- Deploy all resources (RBAC, ConfigMap, Secret, CronJob)
- Keep the deployment in sync with Git

### Manual Trigger

To manually trigger a scan without waiting for the schedule:

```bash
kubectl create job --from=cronjob/k8s-image-updater manual-scan -n image-updater
kubectl logs -n image-updater job/manual-scan -f
```

## Monitoring

View CronJob status:
```bash
kubectl get cronjob -n image-updater
kubectl get jobs -n image-updater
```

View logs from the last run:
```bash
kubectl logs -n image-updater -l app=k8s-image-updater --tail=100
```

## Schedule

The CronJob runs every Monday at 9:00 AM UTC. To change the schedule, edit the `schedule` field in [cronjob.yaml](cronjob.yaml):

```yaml
spec:
  schedule: "0 9 * * 1"  # Cron format: minute hour day month weekday
```

## Resources

- **Repository**: https://github.com/mtstrong/k8s-image-updater
- **Container Image**: ghcr.io/mtstrong/k8s-image-updater:latest
- **Documentation**: See the main repository for detailed documentation

## Troubleshooting

### Image Pull Errors
Make sure the GHCR package is public:
1. Go to https://github.com/mtstrong?tab=packages
2. Click on `k8s-image-updater`
3. Package settings → Change visibility → Public

### Permission Errors
Verify the GitHub token has `repo` scope and is correctly set in the secret.

### No PRs Created
Check the logs to see what images were scanned and if any updates were found:
```bash
kubectl logs -n image-updater -l app=k8s-image-updater --tail=200
```
