# APT repo (aptly)

This directory provides a minimal `aptly` flow to host a private APT repo.

## Requirements
- `aptly`
- `gpg` (for signing)
  - Make sure a default GPG key exists (`gpg --list-keys`).

## Publish to GCS (recommended)
This flow syncs the published repo to `gs://apt.plaidai.io` and serves it via `https://apt.plaidai.io`.

```bash
./publish-gcs.sh /path/to/nuv-agent_0.1.0_arm64.deb
```

Requirements:
- `gcloud` + `gsutil`
- A GCS bucket named `apt.plaidai.io`
- A public HTTPS endpoint for the bucket (Cloud CDN + HTTPS Load Balancer recommended)

The repo is published under `.aptly/public` locally and synced to GCS.

Provisioning (GCP):
- `packaging/apt/gcp/setup-apt-hosting.sh`
- `packaging/apt/gcp/README.md`

Client install example (arm64 only):
```bash
sudo install -d /etc/apt/keyrings
sudo curl -fsSL https://apt.plaidai.io/public.gpg -o /etc/apt/keyrings/plaidai.gpg
echo \"deb [signed-by=/etc/apt/keyrings/plaidai.gpg arch=arm64] https://apt.plaidai.io stable main\" | sudo tee /etc/apt/sources.list.d/plaidai.list
sudo apt update
sudo apt install nuv-agent
```

## Local publish
```bash
./publish.sh /path/to/nuv-agent_0.1.0_arm64.deb
```
The repo is published under `.aptly/public`. You can serve it via nginx.

## Kubernetes hosting (optional)
See `packaging/apt/k8s/README.md` for a minimal Nginx deployment that serves the repo from a PVC.
