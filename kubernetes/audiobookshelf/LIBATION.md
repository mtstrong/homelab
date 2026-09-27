# Libation automation

Libation scans the Audible library every 6 hours (`SLEEP_TIME`), downloads new
purchases, removes DRM and writes M4B files straight to the TrueNAS NFS export
that Audiobookshelf mounts at `/audiobooks`. It has no web UI.

| Mount     | Source                                      |
|-----------|---------------------------------------------|
| `/config` | `libation-config` Secret (read-only)        |
| `/db`     | `libation-db` Longhorn volume (SQLite DB)   |
| `/data`   | `192.168.1.70:/mnt/TrueNAS/audiobooks`      |

The container runs as 1000:1000 to match the group that owns the audiobooks
share. On the share, everything is owned by root with group 1000, and
directories are group-writable with setgid. Re-apply `chgrp -R 1000` and
`chmod g+rwxs` on directories if books are copied onto the share as root.

## Audible login

The container cannot complete an interactive Audible login through the Rancher
proxy, so sign in with the Libation desktop app (same major version as the
image) and copy its settings into a Secret:

1. Sign in to the Audible account in desktop Libation.
2. Under **Settings > Download/Decrypt**, set the folder template to
   Author/Series/Title (check the editor's preview) and keep output as a
   single M4B file.
3. Create the Secret from the desktop Libation files folder (default
   `%USERPROFILE%\Libation`). Include `libation-master.key` only if it exists:

```powershell
$L = "$env:USERPROFILE\Libation"
kubectl create secret generic libation-config -n audiobookshelf `
  --from-file="$L\AccountsSettings.json" `
  --from-file="$L\Settings.json" `
  --from-file="$L\libation-master.key" `
  --dry-run=client -o yaml | kubectl apply -f -
kubectl rollout restart deployment/libation -n audiobookshelf
```

The Secret holds Audible tokens and is intentionally not stored in Git.
Repeat these steps if Audible revokes the login.

## Existing books

Libation downloads every title it has not marked as downloaded. Before the
first run, books already on the share were marked downloaded with a one-off
`LibationCli scan` followed by `LibationCli set-status --downloaded --force <asins>`.
To re-download a title, mark it pending the same way with
`--download-pending --force <asin>`.

## Audiobookshelf

Schedule an automatic library scan in the audiobook library's settings. The
folder watcher does not reliably see changes on the NFS share.

## Operations

```powershell
kubectl logs deployment/libation -n audiobookshelf --tail=100
kubectl rollout restart deployment/libation -n audiobookshelf  # scan now
```
