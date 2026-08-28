# OpenAudible automation

OpenAudible is available at `http://192.168.2.137:3000` through a private
MetalLB address. Its configuration and downloaded AAX files are stored on the
`openaudible-config` Longhorn volume. Converted books are written directly to
the same TrueNAS NFS export that Audiobookshelf mounts at `/audiobooks`.

## Initial setup

1. From the LAN, open `http://192.168.2.137:3000` and wait for the web desktop
   and OpenAudible installer to finish loading.
2. Activate an OpenAudible license. Demo mode cannot convert audiobooks.
3. Connect the Audible account using **Controls > Connect to Audible** and
   complete any MFA or CAPTCHA prompts.
4. Keep the OpenAudible library directory set to `/config/OpenAudible`. The
   `books` directory beneath it is the shared Audiobookshelf library.
5. Under **File > Library Settings**, enable advanced file naming and select
   **Author/Series/Title**. Keep **One audiobook per directory** enabled.
6. Under **Edit > Preferences**, select M4B and enable:
   - **Refresh library on application startup**
   - **Automatically download books**
   - **Automatically convert**
7. In Audiobookshelf, enable a periodic scan for the audiobook library. A scan
   interval after 04:00 gives the daily download and conversion time to finish.

The `openaudible-restart` CronJob restarts OpenAudible daily at 03:00 America/Chicago.
The startup refresh discovers new purchases; OpenAudible then downloads and
converts them using the saved automation settings. Audiobookshelf discovers the
completed M4B on its next scheduled library scan.

## Operations

Trigger the automation outside the daily schedule:

```powershell
kubectl rollout restart deployment/openaudible -n audiobookshelf
```

Check OpenAudible and the scheduled restart:

```powershell
kubectl get pods,cronjobs,jobs -n audiobookshelf
kubectl logs deployment/openaudible -n audiobookshelf --tail=100
```

OpenAudible's Docker image is experimental and only published for AMD64. The web
desktop has no native password protection, so keep `192.168.2.137:3000`
restricted to the trusted LAN and do not port-forward it from the router. The
pod uses the unconfined seccomp profile required by the upstream image to
auto-start OpenAudible; keep this exception limited to this pod.