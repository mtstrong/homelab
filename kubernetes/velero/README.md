# Velero (Argo CD + Helm)

Helm values for Velero, deployed by the Argo app `kubernetes/argocd/apps/velero.yaml`.

- **What it backs up:** Kubernetes objects in every namespace, daily at 04:30, kept 30 days. That includes
  Secrets that aren't in git. Volume data is left to Longhorn's nightly backups to TrueNAS.
- **Where:** the Garage S3 app on TrueNAS (`http://192.168.1.70:30188`, region `garage`, bucket `velero`).
  Garage's admin API is on port 30190; its admin token is in the user's `~/.garage-secrets`.
- **Credentials:** the Secret `velero-credentials` in the `velero` namespace (key `cloud`, AWS
  credentials-file format), created by hand from a Garage key named `velero`. Not in git.

Restore one app: restore its volume from Longhorn's backup, then
`velero restore create --from-backup <backup> --include-namespaces <ns>`.
