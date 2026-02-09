# K8s Image Updater - Homelab Deployment Summary

## ✅ Completed Successfully

### 1. Repository Setup
- ✓ Created GitHub repository: https://github.com/mtstrong/k8s-image-updater
- ✓ Set up GitHub Actions CI/CD pipeline
- ✓ Fixed Python import bug in changelog_fetcher.py
- ✓ Container image building successfully: `ghcr.io/mtstrong/k8s-image-updater:latest`

### 2. Homelab Integration
- ✓ Created feature branch: `add-k8s-image-updater`
- ✓ Added Kubernetes manifests in `/kubernetes/k8s-image-updater/`
  - namespace.yaml
  - serviceaccount.yaml
  - clusterrole.yaml
  - clusterrolebinding.yaml
  - configmap.yaml
  - secret.yaml (placeholder)
  - cronjob.yaml
  - README.md
- ✓ Created ArgoCD Application: `/argocd/k8s-image-updater-application.yaml`
- ✓ Committed and pushed to branch
- ✓ Branch URL: https://github.com/mtstrong/homelab/tree/add-k8s-image-updater

### 3. Cluster Deployment
- ✓ Namespace `image-updater` created
- ✓ ArgoCD Application deployed and synced (using branch temporarily)
- ✓ All Kubernetes resources deployed via ArgoCD
- ✓ CronJob scheduled for every Monday at 9 AM UTC

## ⚠️ Action Required

### 1. Make GHCR Image Public
The container image needs to be public for Kubernetes to pull it without authentication:

1. Visit: https://github.com/mtstrong?tab=packages
2. Click on `k8s-image-updater` package
3. Go to "Package settings"
4. Under "Danger Zone", click "Change visibility"
5. Select "Public"

### 2. Create Proper GitHub Token
The current token doesn't have the required `repo` scope. Create a new token:

1. Visit: https://github.com/settings/tokens/new
2. Give it a name: "k8s-image-updater-homelab"
3. Select scopes:
   - ✅ `repo` (full control of private repositories)
4. Generate token
5. Save the token

Then update the Kubernetes secret:
```bash
kubectl create secret generic github-token \
  --from-literal=token=YOUR_NEW_TOKEN \
  --namespace=image-updater \
  --dry-run=client -o yaml | kubectl apply -f -
```

### 3. Test the Deployment
After fixing the token:
```bash
# Create a manual test job
kubectl create job --from=cronjob/k8s-image-updater test-run -n image-updater

# Watch the logs
kubectl logs -n image-updater -l app=k8s-image-updater -f
```

### 4. Merge to Main (Optional)
Once everything is working:
```bash
cd /home/matt/code/homelab
git checkout main
git merge add-k8s-image-updater
git push origin main
```

Then update the ArgoCD app to track main:
```bash
kubectl patch application k8s-image-updater -n argocd \
  --type merge \
  -p '{"spec":{"source":{"targetRevision":"main"}}}'
```

## 📋 How It Works

1. **CronJob Schedule**: Runs every Monday at 9:00 AM UTC
2. **Init Container**: Clones the homelab repository
3. **Main Container**: 
   - Scans all Kubernetes deployments
   - Checks for image updates (DockerHub, LSCR, GHCR)
   - Creates GitHub PRs with update details
4. **You Review**: Review and merge the PR to update images

## 🔧 Configuration

Current configuration (in ConfigMap):
- **Repository**: `mtstrong/homelab`
- **Scan Path**: `/workspace/kubernetes/`
- **Update Policy**: 
  - ✅ Minor updates
  - ✅ Patch updates
  - ❌ Major updates (disabled for safety)
- **AI Features**: Disabled (can be enabled with OpenAI API key)

## 📊 Monitoring

View all resources:
```bash
kubectl get all -n image-updater
```

View CronJob schedule:
```bash
kubectl get cronjob -n image-updater
```

View job history:
```bash
kubectl get jobs -n image-updater
```

View logs:
```bash
kubectl logs -n image-updater -l app=k8s-image-updater --tail=100
```

## 🔄 Making Updates

When you update the k8s-image-updater code:
1. GitHub Actions automatically builds new image
2. ArgoCD detects changes (if watching main)
3. Optionally restart the deployment:
   ```bash
   kubectl delete jobs -n image-updater --all
   ```

## 📁 Files Created

### In homelab repository:
- `kubernetes/k8s-image-updater/` - All K8s manifests
- `argocd/k8s-image-updater-application.yaml` - ArgoCD app definition

### In k8s-image-updater repository:
- `.github/workflows/docker-build.yml` - CI/CD pipeline
- `DEPLOYMENT.md` - Deployment guide
- `SETUP_COMPLETE.md` - Setup summary
- `deploy.sh` - Quick deployment script

## 🎯 Current Status

**Branch**: `add-k8s-image-updater` (pushed to GitHub)
**ArgoCD**: Synced and deployed (tracking branch temporarily)
**Cluster**: Resources deployed, waiting for valid GitHub token

---

**Next Step**: Complete the two action items above (make image public & create proper token), then test!
