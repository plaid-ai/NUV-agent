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
text = text.replace("__URL__", url)
text = text.replace("__SHA256__", sha)
text = re.sub(r'url\s+"[^"]+"', f'url "{url}"', text)
text = re.sub(r'sha256\s+"[^"]+"', f'sha256 "{sha}"', text)
version = "$VERSION"
text = re.sub(r'version\s+"[^"]+"', f'version "{version}"', text)
path.write_text(text)
print(f"Updated: {path}")
PY
