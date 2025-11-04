#!/usr/bin/env bash
# vault-kv-get.sh — Read secrets from HashiCorp Vault KV v2 via a short-lived pod in Kubernetes
#
# Features
# - No local Vault CLI needed; uses kubectl and an ephemeral Alpine pod
# - Installs curl+jq in the pod for robust JSON parsing
# - Returns full JSON or a single value by key
#
# Usage
#   scripts/vault-kv-get.sh \
#     --token <VAULT_TOKEN> \
#     --path apps/vaultwarden \
#     [--key ADMIN_TOKEN] [--mount kv] [--namespace vault] [--service vault] [--image alpine:3.20]
#
# Examples
#   # Full JSON
#   scripts/vault-kv-get.sh --token "$VAULT_TOKEN" --path apps/vaultwarden
#   
#   # Single key value
#   scripts/vault-kv-get.sh --token "$VAULT_TOKEN" --path apps/vaultwarden --key ADMIN_TOKEN

set -euo pipefail

# Defaults
NAMESPACE="vault"
SERVICE="vault"
MOUNT="kv"
IMAGE="alpine:3.20"
TOKEN="${VAULT_TOKEN:-}"
SECRET_REL_PATH=""
EXTRACT_KEY=""

print_usage() {
  sed -n '1,80p' "$0"
}

# Parse flags
while [[ $# -gt 0 ]]; do
  case "$1" in
    --namespace|-n) NAMESPACE="$2"; shift 2;;
    --service|-s) SERVICE="$2"; shift 2;;
    --mount|-m) MOUNT="$2"; shift 2;;
    --token|-t) TOKEN="$2"; shift 2;;
    --path|-p) SECRET_REL_PATH="$2"; shift 2;;
    --image) IMAGE="$2"; shift 2;;
    --key) EXTRACT_KEY="$2"; shift 2;;
    --help|-h) print_usage; exit 0;;
    *) echo "[error] Unknown argument: $1" >&2; print_usage; exit 2;;
  esac
done

# Validate
if [[ -z "$TOKEN" ]]; then echo "[error] --token required (or export VAULT_TOKEN)" >&2; exit 2; fi
if [[ -z "$SECRET_REL_PATH" ]]; then echo "[error] --path required (e.g., apps/vaultwarden)" >&2; exit 2; fi

VAULT_ADDR="http://${SERVICE}.${NAMESPACE}.svc:8200"

read_cmd='set -euo pipefail
apk add --no-cache curl jq >/dev/null
resp=$(curl -sS -H "X-Vault-Token: $TOKEN" "$VAULT_ADDR/v1/$MOUNT/data/$SECRET_PATH")
if [ -n "${EXTRACT_KEY:-}" ]; then
  echo "$resp" | jq -er ".data.data[\"$EXTRACT_KEY\"]"
else
  echo "$resp" | jq -C .
fi
'

kubectl -n "$NAMESPACE" run kv-reader --rm -i --restart=Never --image="$IMAGE" \
  --env="TOKEN=$TOKEN" \
  --env="VAULT_ADDR=$VAULT_ADDR" \
  --env="MOUNT=$MOUNT" \
  --env="SECRET_PATH=$SECRET_REL_PATH" \
  --env="EXTRACT_KEY=$EXTRACT_KEY" \
  -- sh -lc "$read_cmd"
