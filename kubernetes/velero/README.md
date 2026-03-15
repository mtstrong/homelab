# Velero (Argo CD + Helm)

This folder provides Helm values for Velero, deployed via Argo CD.

## Required setup
- Create a secret named velero-credentials in the velero namespace.
- Update values.yaml to match your backup target (S3-compatible or cloud object storage).

## Example secret
Use your preferred secret workflow (Vault/AVP, External Secrets, or kubectl) to create:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: velero-credentials
  namespace: velero
stringData:
  cloud: |
    [default]
    aws_access_key_id=REPLACE_ME
    aws_secret_access_key=REPLACE_ME
```
