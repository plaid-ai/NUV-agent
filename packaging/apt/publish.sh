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
PUBLIC_DIR="$ROOT_DIR/.aptly/public"
PUBLIC_KEY_PATH="$PUBLIC_DIR/public.gpg"
INSTALL_SCRIPT_SRC="$ROOT_DIR/install-apt.sh"
INSTALL_SCRIPT_DST="$PUBLIC_DIR/install-apt.sh"

aptly -config="$APTLY_CONFIG" repo create -distribution="$DIST" -component="$COMPONENT" "$REPO_NAME" || true
aptly -config="$APTLY_CONFIG" repo add "$REPO_NAME" "$DEB_PATH"

if aptly -config="$APTLY_CONFIG" publish list | grep -q "^$DIST"; then
  aptly -config="$APTLY_CONFIG" publish update -distribution="$DIST" "$REPO_NAME"
else
  aptly -config="$APTLY_CONFIG" publish repo -distribution="$DIST" -architectures="$ARCH" -component="$COMPONENT" "$REPO_NAME"
fi

if ! command -v gpg >/dev/null 2>&1; then
  echo "gpg not found. Install gpg to export the public key." >&2
  exit 1
fi

mkdir -p "$PUBLIC_DIR"
if [ ! -s "$PUBLIC_KEY_PATH" ]; then
  echo "Exporting public GPG key to $PUBLIC_KEY_PATH"
  if [ -n "${GPG_KEY_ID:-}" ]; then
    gpg --armor --export "$GPG_KEY_ID" > "$PUBLIC_KEY_PATH"
  else
    gpg --armor --export > "$PUBLIC_KEY_PATH"
  fi
fi

if [ ! -s "$PUBLIC_KEY_PATH" ]; then
  echo "Failed to export public key. Set GPG_KEY_ID and retry." >&2
  exit 1
fi

if [ -f "$INSTALL_SCRIPT_SRC" ]; then
  cp "$INSTALL_SCRIPT_SRC" "$INSTALL_SCRIPT_DST"
  chmod 0644 "$INSTALL_SCRIPT_DST"
fi

aptly -config="$APTLY_CONFIG" publish list
