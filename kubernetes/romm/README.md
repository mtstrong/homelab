# RomM on Kubernetes

This folder contains Kubernetes manifests to deploy [RomM](https://romm.app/) and a MariaDB database, matching the style used elsewhere in this repo (namespace file, PVCs, Deployment, Service, and Traefik IngressRoute).

## Components

- Namespace: `romm`
- Secrets (created with kubectl, see Prereqs):
  - `romm-secrets` (app env incl. DB creds and provider API keys)
  - `romm-db-secrets` (MariaDB root/user credentials)
- Storage (PVCs):
  - `romm-resources-pvc` (covers, screenshots, etc.)
  - `romm-redis-pvc` (internal cache)
  - `romm-assets-pvc` (uploads: saves, states, etc.)
  - `romm-config-pvc` (config.yml lives here)
  - `romm-library-pvc` (ROM library, NFS from TrueNAS)
  - `romm-mysql-pvc` (MariaDB data)
- Workloads:
  - `Deployment/romm-db` (MariaDB)
  - `Deployment/romm` (RomM)
- Networking:
  - `Service/romm-db` (ClusterIP :3306)
  - `Service/romm` (ClusterIP :80 -> container :8080)
  - `IngressRoute/romm` (Traefik, default TLS cert)

## Prereqs

- Secrets are created by hand with kubectl (not in git; Vault is not running):
  - `romm-secrets`: `DB_NAME`, `DB_USER`, `DB_PASSWD`, `ROMM_AUTH_SECRET_KEY` (`openssl rand -hex 32`), `OIDC_CLIENT_SECRET`
    - Optional providers: `IGDB_CLIENT_ID`, `IGDB_CLIENT_SECRET`, `SCREENSCRAPER_USER`, `SCREENSCRAPER_PASSWORD`, `RETROACHIEVEMENTS_API_KEY`, `MOBYGAMES_API_KEY`, `STEAMGRIDDB_API_KEY`, `PLAYMATCH_API_ENABLED`, `HASHEOUS_API_ENABLED`, `LAUNCHBOX_API_ENABLED`
  - `romm-db-secrets`: `MARIADB_ROOT_PASSWORD`, `MARIADB_DATABASE`, `MARIADB_USER`, `MARIADB_PASSWORD`

- ROM library is the TrueNAS dataset `TrueNAS/roms` over NFS, mounted at `/romm/library`. Put games in one folder per platform under `roms/`, e.g. `roms/nes/`, `roms/snes/`. Subfolders inside a platform folder are treated as one multi-file game, so keep platform folders flat.

- Web login uses Authentik OIDC (provider and application `romm`; its email mapping sends `email_verified: true`, which RomM requires). The RomM user's email must match the Authentik user's. There is deliberately no Authentik forward-auth on the IngressRoute: the Argosy Android client calls RomM's API with a local RomM account.

## Notes

- Container image is pinned to `rommapp/romm:5.4.1`. Update as needed.
- MariaDB uses basic liveness/readiness checks. For heavier loads, consider switching to a StatefulSet and tuning resources.
- RomM exposes port 8080 internally; the Service maps it to 80 consistent with other apps.
