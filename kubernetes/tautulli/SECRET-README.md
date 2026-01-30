# Tautulli API Key Secret

To create the secret with your API key, run:

```bash
kubectl create secret generic tautulli-api-key \
  --from-literal=api-key=YOUR_API_KEY_HERE \
  -n tautulli
```

Replace `YOUR_API_KEY_HERE` with your actual Tautulli API key.

This secret is referenced by the tautulli-exporter deployment but is not stored in git.
