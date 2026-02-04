# Kubernetes hosting (optional)

This is a minimal Nginx deployment that serves a static APT repository from a PVC.

## Flow
1. Publish the APT repo locally using `aptly` (see `packaging/apt/publish.sh`).
2. Sync `.aptly/public` into a PVC (e.g., via `kubectl cp` or an init job).
3. Apply `nginx-deployment.yaml` and expose via Ingress.

This is a fallback if you prefer hosting on your own cluster instead of GCS.
