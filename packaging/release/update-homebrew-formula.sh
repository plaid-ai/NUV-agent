#!/usr/bin/env bash
set -euo pipefail

FORMULA_PATH=${FORMULA_PATH:-""}
URL=${URL:-""}
SHA256=${SHA256:-""}
VERSION=${VERSION:-""}

usage() {
  echo "Usage: FORMULA_PATH=... URL=... SHA256=... VERSION=... $0" >&2
}

if [ -z "$FORMULA_PATH" ] || [ -z "$URL" ] || [ -z "$SHA256" ] || [ -z "$VERSION" ]; then
  usage
  exit 1
fi

if [ ! -f "$FORMULA_PATH" ]; then
  echo "Formula not found: $FORMULA_PATH" >&2
  exit 1
fi

python3 - <<PY
from pathlib import Path
import re

path = Path("$FORMULA_PATH")
text = path.read_text()
url = "$URL"
sha = "$SHA256"
version = "$VERSION"

parts = text.split("\n  resource ", 1)
head = parts[0]
tail = f"\n  resource {parts[1]}" if len(parts) > 1 else ""

head = head.replace("__URL__", url)
head = head.replace("__SHA256__", sha)
head = re.sub(r'url\s+"[^"]+"', f'url "{url}"', head, count=1)
head = re.sub(r'sha256\s+"[^"]+"', f'sha256 "{sha}"', head, count=1)
head = re.sub(r'version\s+"[^"]+"', f'version "{version}"', head, count=1)

text = head + tail
path.write_text(text)
print(f"Updated: {path}")
PY
