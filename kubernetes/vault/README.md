# Vault on Kubernetes (Helm)

This folder contains the Helm values and ingress for running HashiCorp Vault in the `vault` namespace.

## What’s included
- `values-helm.yaml` – Helm values for a standalone Vault with integrated (Raft) storage.
  - Vault listens on HTTP internally; TLS is terminated at Traefik.
- `ingress.yaml` – Traefik IngressRoute that serves `https://vault.tehmatt.com` using TLS and forwards to the Vault Service on port 8200 (HTTP).

## Prerequisites
- Helm v3 installed
- Traefik installed and configured with an entryPoint `websecure`
- TLS secret named `tehmatt-tls` in the `vault` namespace (used by the IngressRoute)

## Install
```bash
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

# Install into the vault namespace using the provided values
helm install vault hashicorp/vault \
  -n vault \
  -f values-helm.yaml \
  --create-namespace
```

## Upgrade
```bash
helm upgrade vault hashicorp/vault \
  -n vault \
  -f values-helm.yaml
```

## Ingress
The supplied `ingress.yaml` uses Traefik’s `IngressRoute` with TLS termination:
- Host: `vault.tehmatt.com`
- TLS: `tehmatt-tls` (must exist in the `vault` namespace)
- Backend: Service `vault` port `8200` (HTTP)

Apply/update it with:
```bash
kubectl apply -n vault -f ingress.yaml
```

## Initialization and unseal
After first deploy, Vault is uninitialized and sealed.

1) Initialize (from within the pod or via port-forward):
```bash
# Option A: exec into the pod
kubectl -n vault exec -it statefulset/vault -- vault operator init

# Option B: port-forward then use CLI/API
kubectl -n vault port-forward svc/vault 8200:8200 &
export VAULT_ADDR=http://127.0.0.1:8200
vault operator init
```

2) Unseal:
```bash
kubectl -n vault exec -it statefulset/vault -- vault operator unseal <UNSEAL_KEY>
```

3) Access the UI:
Open https://vault.tehmatt.com and log in with the initial root token (store it securely and prefer creating a non-root admin token for daily use).

## Notes
- With TLS terminated at Traefik, Vault receives HTTP traffic from the ingress. If you prefer end-to-end TLS with Vault terminating TLS, switch to an `IngressRouteTCP` with TLS passthrough and configure a cert in the Vault pod, then update `values-helm.yaml` accordingly.
- Consider restricting inbound traffic to Vault with NetworkPolicies and enabling the Kubernetes auth method for in-cluster clients.

## Troubleshooting
- Pod not Ready with `Initialized false/Sealed true`: run `vault operator init` (first time) and then unseal with the provided key(s).
- 404/connection error at the browser: verify DNS for `vault.tehmatt.com`, the Traefik `websecure` entryPoint, and that `tehmatt-tls` exists in the `vault` namespace.
- CLI cannot connect: port-forward to the Service and set `VAULT_ADDR=http://127.0.0.1:8200` when TLS is terminated at Traefik.
