#!/usr/bin/env bash
# vault-kv-delete.sh — Delete secrets or versions from HashiCorp Vault KV v2 via a short-lived pod
#
# Modes (KV v2):
# - metadata (default): DELETE /v1/<mount>/metadata/<path>  -> removes all versions + metadata (cannot be undone)
# - soft:     POST   /v1/<mount>/delete/<path>    body: {"versions":[1,2]}  -> soft-deletes versions (can be undeleted)
# - destroy:  POST   /v1/<mount>/destroy/<path>   body: {"versions":[1,2]}  -> permanently destroys versions
#
# Usage
#   scripts/vault-kv-delete.sh \
#     --token <VAULT_TOKEN> \
#     --path apps/vaultwarden \
#     [--delete-type metadata|soft|destroy] [--versions "1,2"] \
#     [--mount kv] [--namespace vault] [--service vault] [--image alpine:3.20]
#
# Examples
#   # Remove entire secret (all versions)
#   scripts/vault-kv-delete.sh --token "$VAULT_TOKEN" --path apps/vaultwarden --delete-type metadata
#   
#   # Soft delete versions 1 and 2
#   scripts/vault-kv-delete.sh --token "$VAULT_TOKEN" --path apps/vaultwarden --delete-type soft --versions "1,2"
#   
#   # Permanently destroy versions 3 and 4
#   scripts/vault-kv-delete.sh --token "$VAULT_TOKEN" --path apps/vaultwarden --delete-type destroy --versions "3,4"

set -euo pipefail

# Defaults
NAMESPACE="vault"
SERVICE="vault"
MOUNT="kv"
IMAGE="alpine:3.20"
TOKEN="${VAULT_TOKEN:-}"
SECRET_REL_PATH=""
DELETE_TYPE="metadata"
VERSIONS=""

print_usage() {
  sed -n '1,120p' "$0"
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
    --delete-type) DELETE_TYPE="$2"; shift 2;;
    --versions) VERSIONS="$2"; shift 2;;
    --help|-h) print_usage; exit 0;;
    *) echo "[error] Unknown argument: $1" >&2; print_usage; exit 2;;
  esac
done

# Validate
if [[ -z "$TOKEN" ]]; then echo "[error] --token required (or export VAULT_TOKEN)" >&2; exit 2; fi
if [[ -z "$SECRET_REL_PATH" ]]; then echo "[error] --path required (e.g., apps/vaultwarden)" >&2; exit 2; fi
case "$DELETE_TYPE" in
  metadata|soft|destroy) :;;
  *) echo "[error] --delete-type must be metadata|soft|destroy" >&2; exit 2;;
esac
if [[ "$DELETE_TYPE" != "metadata" && -z "$VERSIONS" ]]; then
  echo "[error] --versions required for delete-type $DELETE_TYPE (e.g., \"1,2\")" >&2
  exit 2
fi

VAULT_ADDR="http://${SERVICE}.${NAMESPACE}.svc:8200"

# Prepare pod command
pod_cmd='set -euo pipefail
apk add --no-cache curl jq >/dev/null
case "$DELETE_TYPE" in
  metadata)
    # delete entire secret metadata
    code=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE -H "X-Vault-Token: $TOKEN" "$VAULT_ADDR/v1/$MOUNT/metadata/$SECRET_PATH")
    ;;
  soft|destroy)
    # build JSON array of integer versions from comma list
    IFS="," read -r -a parts <<< "$VERSIONS"
    arr="["; sep=""; for p in "${parts[@]}"; do arr="$arr$sep$((p+0))"; sep=","; done; arr="$arr]"
    body="{\"versions\":$arr}"
    endpoint="$VAULT_ADDR/v1/$MOUNT/$DELETE_TYPE/$SECRET_PATH"
    code=$(curl -s -o /dev/null -w "%{http_code}" -X POST -H "X-Vault-Token: $TOKEN" -H "Content-Type: application/json" -d "$body" "$endpoint")
    ;;
  *) echo "unknown delete type" >&2; exit 2;;
esac
if [ "$code" = "204" ] || [ "$code" = "200" ]; then
  echo "[ok] delete ($DELETE_TYPE) succeeded with HTTP $code"
else
  echo "[error] delete ($DELETE_TYPE) failed with HTTP $code" >&2
  exit 1
fi
'

# Run ephemeral pod
kubectl -n "$NAMESPACE" run kv-deleter --rm -i --restart=Never --image="$IMAGE" \
  --env="TOKEN=$TOKEN" \
  --env="VAULT_ADDR=$VAULT_ADDR" \
  --env="MOUNT=$MOUNT" \
  --env="SECRET_PATH=$SECRET_REL_PATH" \
  --env="DELETE_TYPE=$DELETE_TYPE" \
  --env="VERSIONS=$VERSIONS" \
  -- sh -lc "$pod_cmd"
