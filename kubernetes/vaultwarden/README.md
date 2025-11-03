Vaultwarden with Argo CD Vault Plugin (AVP)

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

Notes
- If your Vault KV v2 mount is named `secret`, change the annotation to `secret/data/apps/vaultwarden` in `secret.avp.yaml`.
- In-cluster clients should use the Service `vaultwarden.vaultwarden.svc`.
- External access is provided via Traefik IngressRoute at `vw.tehmatt.com`.
Vaultwarden on Kubernetes

This folder contains manifests to run Vaultwarden in the cluster. It follows the same patterns as other app folders here: namespace, PVC + Deployment, Service, Traefik IngressRoute, and a default security headers middleware.

Secrets: create a secret named "vaultwarden-secrets" in the "vaultwarden" namespace with at least ADMIN_TOKEN (required). Optional keys: DOMAIN, SMTP_FROM, SMTP_HOST, SMTP_PORT, SMTP_USERNAME, SMTP_PASSWORD, SMTP_SECURITY.

Adjustments: update service.yaml loadBalancerIP, ingress.yaml host and TLS secret, and deployment resources/PVC size as needed.

Deployment order: apply _namespace.yaml, default-headers.yaml, deployment.yaml, service.yaml, then ingress.yaml.

Notes: WebSockets route for /notifications/hub is included; signups are disabled by default; data is stored under /data in the PVC.