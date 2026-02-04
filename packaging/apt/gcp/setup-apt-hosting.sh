#!/usr/bin/env bash
set -euo pipefail

PROJECT=${PROJECT:-$(gcloud config get-value project 2>/dev/null)}
BUCKET=${BUCKET:-apt.plaidai.io}
DOMAIN=${DOMAIN:-apt.plaidai.io}
LOCATION=${LOCATION:-US}
DNS_ZONE=${DNS_ZONE:-}
BACKEND_BUCKET=${BACKEND_BUCKET:-apt-repo-backend}
URL_MAP=${URL_MAP:-apt-repo-map}
CERT=${CERT:-apt-repo-cert}
HTTPS_PROXY=${HTTPS_PROXY:-apt-repo-https-proxy}
FWD_RULE=${FWD_RULE:-apt-repo-https}

if [ -z "$PROJECT" ]; then
  echo "PROJECT is not set and gcloud config has no project." >&2
  exit 1
fi

if ! command -v gcloud >/dev/null 2>&1; then
  echo "gcloud not found." >&2
  exit 1
fi

if ! command -v gsutil >/dev/null 2>&1; then
  echo "gsutil not found." >&2
  exit 1
fi

if ! gcloud auth list --format='value(account)' >/dev/null 2>&1; then
  echo "gcloud auth missing. Run: gcloud auth login" >&2
  exit 1
fi

set -x

# Bucket
if ! gsutil ls -b "gs://$BUCKET" >/dev/null 2>&1; then
  gsutil mb -p "$PROJECT" -c STANDARD -l "$LOCATION" "gs://$BUCKET"
fi

# Make bucket public for apt clients
if ! gsutil iam get "gs://$BUCKET" | grep -q allUsers; then
  gsutil iam ch allUsers:objectViewer "gs://$BUCKET"
fi

# Backend bucket (Cloud CDN)
if ! gcloud compute backend-buckets describe "$BACKEND_BUCKET" --project "$PROJECT" >/dev/null 2>&1; then
  gcloud compute backend-buckets create "$BACKEND_BUCKET" \
    --gcs-bucket-name="$BUCKET" \
    --enable-cdn \
    --project "$PROJECT"
fi

# URL map
if ! gcloud compute url-maps describe "$URL_MAP" --project "$PROJECT" >/dev/null 2>&1; then
  gcloud compute url-maps create "$URL_MAP" \
    --default-backend-bucket="$BACKEND_BUCKET" \
    --project "$PROJECT"
fi

# Managed certificate
if ! gcloud compute ssl-certificates describe "$CERT" --project "$PROJECT" >/dev/null 2>&1; then
  gcloud compute ssl-certificates create "$CERT" \
    --domains="$DOMAIN" \
    --project "$PROJECT"
fi

# HTTPS proxy
if ! gcloud compute target-https-proxies describe "$HTTPS_PROXY" --project "$PROJECT" >/dev/null 2>&1; then
  gcloud compute target-https-proxies create "$HTTPS_PROXY" \
    --ssl-certificates="$CERT" \
    --url-map="$URL_MAP" \
    --project "$PROJECT"
fi

# Forwarding rule
if ! gcloud compute forwarding-rules describe "$FWD_RULE" --global --project "$PROJECT" >/dev/null 2>&1; then
  gcloud compute forwarding-rules create "$FWD_RULE" \
    --global \
    --target-https-proxy="$HTTPS_PROXY" \
    --ports=443 \
    --project "$PROJECT"
fi

IP=$(gcloud compute forwarding-rules describe "$FWD_RULE" --global --project "$PROJECT" --format='value(IPAddress)')
set +x

echo "HTTPS LB IP: $IP"

if [ -n "$DNS_ZONE" ]; then
  echo "Creating DNS record in zone: $DNS_ZONE"
  gcloud dns record-sets transaction start --zone "$DNS_ZONE"
  gcloud dns record-sets transaction add "$IP" \
    --name "$DOMAIN." \
    --ttl 300 \
    --type A \
    --zone "$DNS_ZONE"
  gcloud dns record-sets transaction execute --zone "$DNS_ZONE"
else
  echo "DNS_ZONE not set. Create an A record for $DOMAIN -> $IP in your DNS provider."
fi

echo "Done. It can take a few minutes for the managed cert to become ACTIVE."
