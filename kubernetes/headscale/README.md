# Headscale on K3s (Argo CD)

This directory deploys Headscale as a single-replica control server with persistent SQLite storage.

## Important values to customize

- Update `server_url` in `configmap.yaml` to your public DNS name.
- Update Ingress host in `ingress.yaml` to match that same DNS name.
- Confirm DNS points to your Traefik entrypoint.

## Deploy

Headscale is deployed by Argo CD from:

- `kubernetes/argocd/apps/headscale.yaml`
- `kubernetes/argocd/kustomization.yaml`

## Post-deploy bootstrap

Create namespace/user and a reusable preauth key:

```bash
kubectl -n headscale exec deploy/headscale -- \
  headscale users create nas

kubectl -n headscale exec deploy/headscale -- \
  headscale preauthkeys create --user nas --reusable --expiration 0
```

List nodes:

```bash
kubectl -n headscale exec deploy/headscale -- headscale nodes list
```

## Synology / remote client join

On a Tailscale client (including Synology), use your Headscale URL instead of the default control plane:

```bash
tailscale up --login-server https://headscale.tehmatt.com --auth-key <preauth-key>
```

Replace with your real hostname and generated key.

## ACL policy for Synology-only access

This deployment includes a starter ACL policy in `configmap.yaml` (`acl.hujson`).

What it does:

- Creates `group:nas-admins`
- Allows only that group to reach `tag:synology` on ports 22, 445, 5000, 5001, 2049
- Leaves all other traffic denied by default

Customize before use:

1. Replace `you@headscale` in the ACL with your real Headscale user(s)
2. Tag your Synology node as `tag:synology` when joining it

Example Synology/client join with tag:

```bash
tailscale up \
  --login-server https://headscale.tehmatt.com \
  --auth-key <preauth-key> \
  --advertise-tags=tag:synology
```

After sync/restart, verify policy is active:

```bash
kubectl -n headscale exec deploy/headscale -- \
  headscale nodes list
```
