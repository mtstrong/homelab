# Vaultwarden on Kubernetes — Auto-Rollout on Secret Changes

This deployment uses Argo CD + Argo CD Vault Plugin (AVP) to render secrets from Vault at deploy time. To roll pods automatically when secret values change, we render a non-sensitive revision value from Vault into the pod template annotation.

- Annotation in `deployment.yaml`:
  - `rollme: <REV>`
- REV is stored in Vault at `kv/apps/vaultwarden` alongside other app secrets.
- When REV changes, the Deployment template changes, and Kubernetes creates a new ReplicaSet (automatic rollout). No manual restart needed.

## How it works

- AVP is configured for this app via annotations and CMP v2.
- On every Argo CD sync, AVP reads `kv/apps/vaultwarden` (KV v2) and replaces placeholders like `<REV>`.
- The Deployment’s pod template includes `rollme: <REV>`; changing REV triggers a rollout.

## Bump the rollout (update REV)

You can set REV to any new string/number (timestamp, counter, etc.). Examples:

- Set to a specific value:
  - `vault kv patch kv/apps/vaultwarden REV="2"`
- Set to current epoch seconds:
  - `vault kv patch kv/apps/vaultwarden REV="$(date +%s)"`

Argo CD is set to auto-sync. If you want an immediate re-render, trigger a hard refresh of the Application.

## Verify

- Check the rendered annotation value:
  - `kubectl -n vaultwarden get deploy vaultwarden -o jsonpath='{.spec.template.metadata.annotations.rollme}'`
- Watch rollout status:
  - `kubectl -n vaultwarden rollout status deploy/vaultwarden`

## Notes

- REV is non-sensitive on purpose; do not put secret values in annotations.
- Updating secret data alone does not restart pods automatically for env vars. Bump REV when you update secrets that should force a restart.
- Current Vault keys used by this app include: `ADMIN_TOKEN`, `DOMAIN`, `SMTP_*`, and `REV`.

## Troubleshooting

- If `rollme` doesn’t render and shows `<REV>` literally, ensure the AVP annotations are present on the Deployment (resource metadata) and that Vault contains a `REV` key under `kv/apps/vaultwarden`.
- To see current Vault values (in-cluster), run a one-off job that executes `vault kv get kv/apps/vaultwarden`.Vaultwarden with Argo CD Vault Plugin (AVP)

Overview
- `secret.avp.yaml` is processed by AVP at sync time to generate the `vaultwarden-secrets` Secret.
- Values are pulled from HashiCorp Vault (KV v2) at `kv/data/apps/vaultwarden` by default.
- The Deployment (`deployment.yaml`) references `vaultwarden-secrets` for ADMIN_TOKEN, SMTP_*, and DOMAIN.

Requirements
- Argo CD with CMP v2 and AVP sidecar configured (already present in this repo).
- A Vault KV v2 mount named `kv` (adjust the annotation if your mount is `secret`).
- The Argo CD repo-server ServiceAccount authorized to read the Vault path via Kubernetes auth.

Populate Vault
1) Write your secrets to Vault (KV v2):
   - Path: `kv/data/apps/vaultwarden`
   - Data keys: `ADMIN_TOKEN`, `DOMAIN`, `SMTP_FROM`, `SMTP_HOST`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `SMTP_SECURITY`

Deploy via Argo CD
- Ensure your Argo CD Application includes this `kubernetes/vaultwarden` directory.
- AVP will detect `secret.avp.yaml` and replace placeholders with the Vault values at sync.

Argo CD Application
- This repo includes an Application manifest at `kubernetes/argocd/apps/vaultwarden.yaml`.
- To apply it alongside Argo CD, run your existing Argo CD kustomization apply, or apply the file directly:
   - `kubectl apply -f kubernetes/argocd/apps/vaultwarden.yaml -n argocd`
   - Or: `kubectl apply -k kubernetes/argocd`
   - It deploys to the `vaultwarden` namespace and will create it if missing (CreateNamespace=true).

Notes
- If your Vault KV v2 mount is named `secret`, change the annotation to `secret/data/apps/vaultwarden` in `secret.avp.yaml`.
- In-cluster clients should use the Service `vaultwarden.vaultwarden.svc`.
- External access is provided via Traefik IngressRoute at `vw.tehmatt.com`.
 - The WebSocket route for notifications is `/notifications/hub` and must be on the same host.
Vaultwarden on Kubernetes

This folder contains manifests to run Vaultwarden in the cluster. It follows the same patterns as other app folders here: namespace, PVC + Deployment, Service, Traefik IngressRoute, and a default security headers middleware.

Secrets: create a secret named "vaultwarden-secrets" in the "vaultwarden" namespace with at least ADMIN_TOKEN (required). Optional keys: DOMAIN, SMTP_FROM, SMTP_HOST, SMTP_PORT, SMTP_USERNAME, SMTP_PASSWORD, SMTP_SECURITY.

Adjustments: update service.yaml loadBalancerIP, ingress.yaml host and TLS secret, and deployment resources/PVC size as needed.

Deployment order: apply _namespace.yaml, default-headers.yaml, deployment.yaml, service.yaml, then ingress.yaml.

Notes: WebSockets route for /notifications/hub is included; signups are disabled by default; data is stored under /data in the PVC.