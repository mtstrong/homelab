#!/usr/bin/env bash
# vault-kv-put.sh — Write secrets to HashiCorp Vault KV v2 via a short-lived curl pod in Kubernetes
#
# Features
# - No local vault CLI needed; uses kubectl and an ephemeral curl pod
# - Enables KV v2 at the mount path if it’s not already mounted
# - Avoids complex quoting by passing key/values as env vars to the pod
#
# Requirements
# - kubectl configured for your cluster
# - Access to the target namespace
# - A valid Vault token with permission to mount (if needed) and write to the target path
#
# Usage
#   scripts/vault-kv-put.sh \
#     --token <VAULT_TOKEN> \
#     --path apps/vaultwarden \
#     [--mount kv] [--namespace vault] [--service vault] [--image curlimages/curl:8.10.1] \
#     KEY=VALUE [KEY=VALUE ...]
#
# Examples
#   scripts/vault-kv-put.sh \
#     --token "$VAULT_TOKEN" \
#     --path apps/vaultwarden \
#     ADMIN_TOKEN='wt/Wdzoeae3lTIX+CD9C6FYT/xBCTiw6RQ81jztzaB4/t8KVG08Jxsz7z+Bt0cLl' \
#     DOMAIN=https://vw.tehmatt.com
#
# Notes
# - SECRET PATH format is relative to the mount, e.g., with --mount kv and --path apps/vaultwarden,
#   the write endpoint is v1/kv/data/apps/vaultwarden
# - This script does NOT log values and does not store tokens in the repo.

set -euo pipefail

# Defaults
NAMESPACE="vault"
SERVICE="vault"
MOUNT="kv"
IMAGE="curlimages/curl:8.10.1"
TOKEN="${VAULT_TOKEN:-}"
SECRET_REL_PATH=""

print_usage() {
  sed -n '1,70p' "$0" | sed -n '1,70p'
}

# Parse flags
while [[ $# -gt 0 ]]; do
  case "$1" in
    --namespace|-n)
      NAMESPACE="$2"; shift 2;;
    --service|-s)
      SERVICE="$2"; shift 2;;
    --mount|-m)
      MOUNT="$2"; shift 2;;
    --token|-t)
      TOKEN="$2"; shift 2;;
    --path|-p)
      SECRET_REL_PATH="$2"; shift 2;;
    --image)
      IMAGE="$2"; shift 2;;
    --help|-h)
      print_usage; exit 0;;
    *=*)
      # KEY=VALUE pair
      KV_ARGS+=("$1"); shift;;
    *)
      echo "[error] Unknown argument: $1" >&2
      print_usage
      exit 2;;
  esac
done

# Validate required inputs
if [[ -z "$TOKEN" ]]; then
  echo "[error] --token is required (or export VAULT_TOKEN env)" >&2
  exit 2
fi
if [[ -z "$SECRET_REL_PATH" ]]; then
  echo "[error] --path is required (e.g., apps/vaultwarden)" >&2
  exit 2
fi
if [[ ${#KV_ARGS[@]:-0} -eq 0 ]]; then
  echo "[error] Provide at least one KEY=VALUE pair" >&2
  exit 2
fi

# Build env flags for kubectl from KEY=VALUE pairs to avoid JSON quoting in the client
ENV_FLAGS=()
idx=0
for pair in "${KV_ARGS[@]}"; do
  key="${pair%%=*}"
  val="${pair#*=}"
  if [[ -z "$key" ]]; then
    echo "[error] Invalid KEY=VALUE: $pair" >&2
    exit 2
  fi
  ENV_FLAGS+=("--env=KV_KEY_${idx}=${key}")
  ENV_FLAGS+=("--env=KV_VAL_${idx}=${val}")
  idx=$((idx+1))
done
ENV_FLAGS+=("--env=KV_N=${idx}")

VAULT_ADDR="http://${SERVICE}.${NAMESPACE}.svc:8200"

# Run ephemeral pod to write secrets
# - Enables kv v2 if the write returns 404
# - Constructs payload from KV_* envs in the pod to avoid client-side quoting issues
exec_cmd='set -euo pipefail
json="{\"data\":{}}"
# Build JSON data object
if [ "${KV_N:-0}" -gt 0 ]; then
  json="{\"data\":{"
  i=0
  first=1
  while [ "$i" -lt "$KV_N" ]; do
    eval k="\${KV_KEY_${i}}"
    eval v="\${KV_VAL_${i}}"
    # Escape double quotes in value
    esc_v=$(printf %s "$v" | sed 's/"/\\"/g')
    if [ "$first" -eq 1 ]; then
      json="$json\"$k\":\"$esc_v\""
      first=0
    else
      json="$json,\"$k\":\"$esc_v\""
    fi
    i=$((i+1))
  done
  json="$json}"}
fi

status=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "X-Vault-Token: $TOKEN" \
  -H "Content-Type: application/json" \
  -d "$json" \
  "$VAULT_ADDR/v1/$MOUNT/data/$SECRET_PATH" || true)

if [ "$status" = "404" ]; then
  echo "[info] mount \"$MOUNT/\" not found; enabling kv v2 at this path"
  curl -sS -H "X-Vault-Token: $TOKEN" -H "Content-Type: application/json" \
    -d "{\"type\":\"kv\",\"options\":{\"version\":\"2\"}}" \
    "$VAULT_ADDR/v1/sys/mounts/$MOUNT" >/dev/null
  # retry write
  status=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "X-Vault-Token: $TOKEN" -H "Content-Type: application/json" \
    -d "$json" "$VAULT_ADDR/v1/$MOUNT/data/$SECRET_PATH")
fi

if [ "$status" != "200" ]; then
  echo "[error] write failed with status $status" >&2
  exit 1
fi

# Optional: read back to confirm
curl -sS -H "X-Vault-Token: $TOKEN" "$VAULT_ADDR/v1/$MOUNT/data/$SECRET_PATH" | sed -e "s/^/[ok] /"
'

# shellcheck disable=SC2145
kubectl -n "$NAMESPACE" run kv-writer --rm -i --restart=Never --image="$IMAGE" \
  --env="TOKEN=$TOKEN" \
  --env="VAULT_ADDR=$VAULT_ADDR" \
  --env="MOUNT=$MOUNT" \
  --env="SECRET_PATH=$SECRET_REL_PATH" \
  "${ENV_FLAGS[@]}" \
  -- sh -lc "$exec_cmd"
