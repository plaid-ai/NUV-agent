#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PKG_NAME="nuv-agent"
VERSION="${VERSION:-0.1.3}"
ARCH="${ARCH:-$(dpkg --print-architecture)}"
BUILD_ROOT="${BUILD_ROOT:-$(mktemp -d)}"

PKG_DIR="$BUILD_ROOT/${PKG_NAME}_${VERSION}_${ARCH}"

mkdir -p "$PKG_DIR/DEBIAN" \
         "$PKG_DIR/opt/nuv-agent" \
         "$PKG_DIR/usr/bin" \
         "$PKG_DIR/lib/systemd/system" \
         "$PKG_DIR/etc/nuv-agent" \
         "$PKG_DIR/opt/nuv-agent/share"

cat > "$PKG_DIR/DEBIAN/control" <<CONTROL
Package: ${PKG_NAME}
Version: ${VERSION}
Section: utils
Priority: optional
Architecture: ${ARCH}
Maintainer: Nuvion <ops@nuvion.ai>
Depends: python3 (>= 3.10), python3-venv, python3-pip, python3-gi, gstreamer1.0-tools, gstreamer1.0-plugins-base, gstreamer1.0-plugins-good, gstreamer1.0-plugins-bad, gstreamer1.0-plugins-ugly, gstreamer1.0-libav, gir1.2-gstreamer-1.0, gir1.2-gst-plugins-base-1.0, libgirepository1.0-1
Description: Nuvion on-device agent
CONTROL

cp "$ROOT_DIR/packaging/deb/postinst" "$PKG_DIR/DEBIAN/postinst"
cp "$ROOT_DIR/packaging/deb/prerm" "$PKG_DIR/DEBIAN/prerm"
chmod 0755 "$PKG_DIR/DEBIAN/postinst" "$PKG_DIR/DEBIAN/prerm"

python3 -m venv "$PKG_DIR/opt/nuv-agent/venv"
PKG_SPEC="$ROOT_DIR"
if [ -n "${EXTRAS:-}" ]; then
  PKG_SPEC="${ROOT_DIR}[${EXTRAS}]"
fi
"$PKG_DIR/opt/nuv-agent/venv/bin/pip" install --no-cache-dir "$PKG_SPEC"

cp "$ROOT_DIR/nuvion_app/config_template.env" "$PKG_DIR/opt/nuv-agent/share/agent.env.example"
cp "$ROOT_DIR/packaging/systemd/nuv-agent.service" "$PKG_DIR/lib/systemd/system/nuv-agent.service"

ln -s /opt/nuv-agent/venv/bin/nuv-agent "$PKG_DIR/usr/bin/nuv-agent"

chmod 0644 "$PKG_DIR/lib/systemd/system/nuv-agent.service"

OUTPUT_DEB="${OUTPUT_DEB:-${ROOT_DIR}/dist/${PKG_NAME}_${VERSION}_${ARCH}.deb}"
mkdir -p "$(dirname "$OUTPUT_DEB")"

if command -v dpkg-deb >/dev/null 2>&1; then
  dpkg-deb --build "$PKG_DIR" "$OUTPUT_DEB"
  echo "Built: $OUTPUT_DEB"
else
  echo "dpkg-deb not found. Install dpkg-dev." >&2
  exit 1
fi
