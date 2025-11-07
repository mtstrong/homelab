# RomM on Kubernetes

This folder contains Kubernetes manifests to deploy [RomM](https://romm.app/) and a MariaDB database, matching the style used elsewhere in this repo (namespace file, AVP-backed secrets, PVCs, Deployment, Service, and Traefik IngressRoute).

## Components

- Namespace: `romm`
- Secrets (Argo CD Vault Plugin):
  - `romm-secrets` (app env incl. DB creds and provider API keys)
  - `romm-db-secrets` (MariaDB root/user credentials)
- Storage (PVCs):
  - `romm-resources-pvc` (covers, screenshots, etc.)
  - `romm-redis-pvc` (internal cache)
  - `romm-assets-pvc` (uploads: saves, states, etc.)
  - `romm-config-pvc` (config.yml lives here)
  - `romm-library-pvc` (ROM library; adjust/replace with NFS as needed)
  - `romm-mysql-pvc` (MariaDB data)
- Workloads:
  - `Deployment/romm-db` (MariaDB)
  - `Deployment/romm` (RomM)
- Networking:
  - `Service/romm-db` (ClusterIP :3306)
  - `Service/romm` (ClusterIP :80 -> container :8080)
  - `IngressRoute/romm` (Traefik, TLS via `tehmatt-tls`)

## Prereqs

- Populate Vault KV with the following keys before syncing:
  - Path `kv/data/apps/romm` (secret `romm-secrets`):
    - `DB_NAME`, `DB_USER`, `DB_PASSWD`
    - `ROMM_AUTH_SECRET_KEY` (generate: `openssl rand -hex 32`)
    - Optional providers: `IGDB_CLIENT_ID`, `IGDB_CLIENT_SECRET`, `SCREENSCRAPER_USER`, `SCREENSCRAPER_PASSWORD`, `RETROACHIEVEMENTS_API_KEY`, `MOBYGAMES_API_KEY`, `STEAMGRIDDB_API_KEY`, `PLAYMATCH_API_ENABLED`, `HASHEOUS_API_ENABLED`, `LAUNCHBOX_API_ENABLED`
  - Path `kv/data/apps/romm/db` (secret `romm-db-secrets`):
    - `MARIADB_ROOT_PASSWORD`, `MARIADB_DATABASE`, `MARIADB_USER`, `MARIADB_PASSWORD`

- Adjust PVC sizes in `deployment.yaml` to suit your storage and library size. If you host the library on NAS/NFS, replace `romm-library-pvc` with an NFS-backed claim or mount.

- Set your domain and TLS secret in `ingress.yaml` (defaults to `romm.tehmatt.com` and `tehmatt-tls`).

## Notes

- Container image is pinned to `rommapp/romm:4.3.2`. Update as needed.
- MariaDB uses basic liveness/readiness checks. For heavier loads, consider switching to a StatefulSet and tuning resources.
- RomM exposes port 8080 internally; the Service maps it to 80 consistent with other apps.
