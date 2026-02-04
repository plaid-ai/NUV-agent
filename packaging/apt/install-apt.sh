#!/usr/bin/env bash
set -euo pipefail

REPO_URL=${REPO_URL:-https://apt.plaidai.io}
DIST=${DIST:-stable}
COMPONENT=${COMPONENT:-main}
ARCH=${ARCH:-$(dpkg --print-architecture)}
KEYRING=/etc/apt/keyrings/plaidai.gpg
LIST_FILE=/etc/apt/sources.list.d/plaidai.list

if ! command -v curl >/dev/null 2>&1; then
  echo "curl not found. Please install curl and retry." >&2
  exit 1
fi

if ! command -v gpg >/dev/null 2>&1; then
  echo "gpg not found. Please install gnupg and retry." >&2
  exit 1
fi

if [ "$ARCH" != "arm64" ]; then
  echo "This APT repo currently publishes arm64 packages only. Detected ARCH=$ARCH." >&2
  exit 1
fi

sudo install -d -m 0755 /etc/apt/keyrings
curl -fsSL "$REPO_URL/public.gpg" | sudo gpg --dearmor -o "$KEYRING"
sudo chmod 0644 "$KEYRING"

echo "deb [signed-by=$KEYRING arch=$ARCH] $REPO_URL $DIST $COMPONENT" | sudo tee "$LIST_FILE" >/dev/null

sudo apt update

if ! apt-cache show libgirepository1.0-1 >/dev/null 2>&1; then
  if ! command -v add-apt-repository >/dev/null 2>&1; then
    sudo apt-get install -y software-properties-common
  fi
  sudo add-apt-repository -y universe
  sudo apt update
fi

sudo apt install -y nuv-agent
