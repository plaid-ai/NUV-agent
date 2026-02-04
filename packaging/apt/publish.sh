#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 /path/to/nuv-agent_*.deb" >&2
  exit 1
fi

DEB_PATH="$1"
if [ ! -f "$DEB_PATH" ]; then
  echo "Deb not found: $DEB_PATH" >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APTLY_CONFIG="$ROOT_DIR/aptly.conf"
REPO_NAME=${REPO_NAME:-nuv-agent}
DIST=${DIST:-stable}
COMPONENT=${COMPONENT:-main}
ARCH=${ARCH:-arm64}

aptly -config="$APTLY_CONFIG" repo create -distribution="$DIST" -component="$COMPONENT" "$REPO_NAME" || true
aptly -config="$APTLY_CONFIG" repo add "$REPO_NAME" "$DEB_PATH"

if aptly -config="$APTLY_CONFIG" publish list | grep -q "^$DIST"; then
  aptly -config="$APTLY_CONFIG" publish update -distribution="$DIST" "$REPO_NAME"
else
  aptly -config="$APTLY_CONFIG" publish repo -distribution="$DIST" -architectures="$ARCH" -component="$COMPONENT" "$REPO_NAME"
fi

aptly -config="$APTLY_CONFIG" publish list
