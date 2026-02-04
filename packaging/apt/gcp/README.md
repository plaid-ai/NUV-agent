# GCP hosting (GCS + HTTPS LB + Cloud CDN)

This script provisions:
- GCS bucket (`apt.plaidai.io`)
- Backend bucket with Cloud CDN
- HTTPS load balancer with managed cert
- Optional Cloud DNS A record

## Usage
```bash
PROJECT=plaid-451114 \
DNS_ZONE=plaidai-io \
./setup-apt-hosting.sh
```

If you don't use Cloud DNS, omit `DNS_ZONE` and create the A record manually.

After the LB is ready, use `publish-gcs.sh` to sync the repo contents.
