# Azure Uptime Kuma - Infrastructure Monitoring

This directory contains OpenTofu/Terraform code for deploying Uptime Kuma on Azure Container Instances, along with comprehensive monitoring and drift detection.

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     GitHub Actions                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Security   │  │    Drift     │  │    Health    │      │
│  │   Scanning   │  │  Detection   │  │    Tests     │      │
│  │   (tfsec)    │  │ (tofu plan)  │  │   (curl)     │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    Azure Resources                           │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Container Instance (Uptime Kuma)                    │   │
│  │  - Public IP + FQDN                                  │   │
│  │  - Port 3001 exposed                                 │   │
│  │  - Persistent storage via Azure Files               │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Storage Account                                      │   │
│  │  - File Share: uptimekuma-data                       │   │
│  │  - Mounts to: /app/data                              │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## 🔍 Monitoring Features

### 1. Security Scanning
- **Tool**: tfsec (Aqua Security)
- **Runs**: On every PR + daily at 2 AM UTC
- **Checks**: 
  - Public IP exposure
  - Storage encryption
  - Access controls
  - Best practice violations
- **Severity**: Blocks on MEDIUM+ issues

### 2. Infrastructure Drift Detection
- **Tool**: OpenTofu plan
- **Runs**: Daily at 2 AM UTC
- **Actions**:
  - Compares Azure actual state vs declared IaC
  - Creates GitHub Issue if drift detected
  - Auto-labels: `infrastructure-drift`, `needs-investigation`
- **Exit Codes**:
  - `0` = No changes (in sync ✅)
  - `2` = Changes detected (drift detected 🚨)

### 3. Health Tests
Comprehensive availability testing:

#### Container Tests
- HTTP accessibility check (with retry logic)
- Response time monitoring (alerts if >3s)
- Container running state verification

#### Azure Resource Tests
- Resource group existence
- Container instance status
- Storage account accessibility
- DNS resolution

### 4. Cost Monitoring
- Monthly cost aggregation by resource
- Reports usage for budget planning
- Runs daily alongside health checks

## 🚀 Workflow Triggers

```yaml
# Daily scheduled run
schedule:
  - cron: '0 2 * * *'  # 2 AM UTC daily

# Manual trigger via GitHub UI
workflow_dispatch:

# On PR changes to infrastructure code
pull_request:
  paths:
    - 'azure-uptimekuma/**'
    - '.github/workflows/azure-uptime-kuma-monitor.yml'
```

## 🔐 Required Secrets

Configure these in GitHub Settings → Secrets and variables → Actions:

| Secret | Description | How to Get |
|--------|-------------|------------|
| `AZURE_CLIENT_ID` | Service Principal App ID | Azure Portal → App Registrations |
| `AZURE_TENANT_ID` | Azure AD Tenant ID | Azure Portal → Tenant properties |
| `AZURE_SUBSCRIPTION_ID` | Subscription ID | Azure Portal → Subscriptions |

### Setting up OIDC Authentication

```bash
# Create service principal
az ad sp create-for-rbac \
  --name "github-actions-uptime-kuma" \
  --role contributor \
  --scopes /subscriptions/{subscription-id}/resourceGroups/rg-uptimekuma-monitoring

# Configure federated credential for OIDC
az ad app federated-credential create \
  --id {app-id} \
  --parameters '{
    "name": "github-actions-main",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:mtstrong/homelab:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

## 📊 Monitoring Dashboard

View results in GitHub Actions:
- **Workflow Runs**: `.github/workflows/azure-uptime-kuma-monitor.yml`
- **Summary**: Auto-generated summary in workflow run
- **Security**: SARIF results uploaded to Security tab
- **Issues**: Auto-created drift detection issues

## 🎯 Interview Talking Points

This monitoring setup demonstrates:

1. **Infrastructure as Code Best Practices**
   - Declarative infrastructure (OpenTofu)
   - Version controlled
   - Automated validation

2. **Security-First Approach**
   - Pre-commit security scanning
   - OIDC authentication (no static credentials)
   - SARIF integration with GitHub Security

3. **Operational Excellence**
   - Proactive drift detection
   - Automated health monitoring
   - Cost visibility
   - Self-documenting via GitHub Issues

4. **CI/CD Pipeline Design**
   - Multi-stage workflow
   - Parallel job execution
   - Conditional logic
   - Failure handling

5. **Observability**
   - Multiple test layers
   - Clear reporting
   - Actionable alerts

## 🛠️ Local Testing

Test the workflow locally before committing:

```bash
# Security scan
docker run --rm -v $(pwd):/src aquasec/tfsec /src/azure-uptimekuma

# Drift detection
cd azure-uptimekuma
tofu init
tofu plan -detailed-exitcode

# Health tests
UPTIME_URL=$(tofu output -raw uptimekuma_url)
curl -f "$UPTIME_URL"
```

## 📈 Extending the Monitoring

Future enhancements:
- Slack/Discord notifications
- Prometheus metrics export
- Automated remediation (tofu apply on drift)
- Performance benchmarking
- Backup validation tests
- Disaster recovery drills

## 🔗 Resources

- [OpenTofu Documentation](https://opentofu.org/docs/)
- [tfsec Rules](https://aquasecurity.github.io/tfsec/)
- [Azure Container Instances](https://learn.microsoft.com/en-us/azure/container-instances/)
- [GitHub Actions - OIDC](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-azure)
