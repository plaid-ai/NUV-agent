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

## GPG key (important)
`aptly` signs the repo with your default GPG key. Make sure the public key you serve
matches the signing key, otherwise clients will see `NO_PUBKEY`.

Tips:
- Use a dedicated signing key for the APT repo.
- Set `GPG_KEY_ID` when running `publish.sh`/`publish-gcs.sh` to export the correct key.
- The publish scripts export `public.gpg` into `.aptly/public/public.gpg` automatically.
- The publish scripts also copy `install-apt.sh` into `.aptly/public/install-apt.sh`.

## GitHub Actions publish (optional)
If you want to publish automatically on tag push, use the `apt-publish` job in
`.github/workflows/release-publish.yml`. It expects an arm64 runner.

Required GitHub secrets:
- `APT_GPG_PRIVATE_KEY`: ASCII-armored private key (export with `gpg --export-secret-keys --armor <KEY_ID>`)
- `APT_GPG_PASSPHRASE`: passphrase for the signing key
- `GCP_SA_KEY`: GCP service account JSON with write access to the bucket
- `GCP_PROJECT_ID`: GCP project ID

Runner note:
- Default is `ubuntu-24.04-arm`. If you don't have access, change the job to `self-hosted`
  and attach an arm64 runner (e.g., Jetson or Graviton).

Provisioning (GCP):
- `packaging/apt/gcp/setup-apt-hosting.sh`
- `packaging/apt/gcp/README.md`

Client install example (arm64 only):
```bash
sudo install -d /etc/apt/keyrings
curl -fsSL https://apt.plaidai.io/public.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/plaidai.gpg
echo \"deb [signed-by=/etc/apt/keyrings/plaidai.gpg arch=arm64] https://apt.plaidai.io stable main\" | sudo tee /etc/apt/sources.list.d/plaidai.list
sudo apt update
sudo apt install nuv-agent
```

One-line install (same steps as above):
```bash
curl -fsSL https://apt.plaidai.io/install-apt.sh | bash
```

## Local publish
```bash
./publish.sh /path/to/nuv-agent_0.1.0_arm64.deb
```
The repo is published under `.aptly/public`. You can serve it via nginx.

## Kubernetes hosting (optional)
See `packaging/apt/k8s/README.md` for a minimal Nginx deployment that serves the repo from a PVC.
