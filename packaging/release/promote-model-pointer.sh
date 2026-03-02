#!/usr/bin/env bash
set -euo pipefail

SOURCE_POINTER=""
TARGET_POINTER=""

usage() {
  cat <<USAGE
Usage:
  $(basename "$0") --source-pointer gs://.../v0002/pointer.json --target-pointer gs://.../pointers/anomalyclip/prod.json

Examples:
  $(basename "$0") \
    --source-pointer gs://nuv-model/nuvion/anomalyclip/v0002/pointer.json \
    --target-pointer gs://nuv-model/pointers/anomalyclip/canary.json

  $(basename "$0") \
    --source-pointer gs://nuv-model/nuvion/anomalyclip/v0002/pointer.json \
    --target-pointer gs://nuv-model/pointers/anomalyclip/prod.json
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source-pointer)
      SOURCE_POINTER="${2:-}"
      shift 2
      ;;
    --target-pointer)
      TARGET_POINTER="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "$SOURCE_POINTER" || -z "$TARGET_POINTER" ]]; then
  usage >&2
  exit 1
fi

if ! command -v gcloud >/dev/null 2>&1; then
  echo "gcloud command is required." >&2
  exit 1
fi

if [[ "$SOURCE_POINTER" != gs://* || "$TARGET_POINTER" != gs://* ]]; then
  echo "Both pointers must be gs:// URIs." >&2
  exit 1
fi

echo "[1/3] validate source pointer JSON: $SOURCE_POINTER"
gcloud storage cat "$SOURCE_POINTER" >/dev/null

echo "[2/3] promote pointer -> $TARGET_POINTER"
gcloud storage cp "$SOURCE_POINTER" "$TARGET_POINTER"

now_utc="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
stamp="$(date -u +%Y%m%dT%H%M%SZ)"
channel_file="${TARGET_POINTER##*/}"
channel="${channel_file%.json}"
target_prefix="${TARGET_POINTER%/*}"
history_uri="${target_prefix}/history/${stamp}-${channel}.json"

tmp_meta="$(mktemp)"
cat > "$tmp_meta" <<META
{
  "promoted_at_utc": "$now_utc",
  "source_pointer": "$SOURCE_POINTER",
  "target_pointer": "$TARGET_POINTER",
  "channel": "$channel"
}
META

echo "[3/3] write promotion history -> $history_uri"
gcloud storage cp "$tmp_meta" "$history_uri"
rm -f "$tmp_meta"

echo "Done."
