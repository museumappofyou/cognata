#!/usr/bin/env bash
# Precompute the forge3d terrain assets used by the Origins page.
#
# Steps:
#   1. venv + forge3d install under tools/forge3d/.venv
#   2. download/assemble the steppe DEM (Mapzen Terrarium tiles)
#   3. path-trace hero + turntable + flyover frames (GPU, Metal/Vulkan)
#   4. encode them into assets/forge3d/*.webp
#
# Usage:
#   scripts/render_assets.sh            # all stages
#   scripts/render_assets.sh hero       # just the hero still
#   scripts/render_assets.sh turntable  # just the 24 orbit frames
#   scripts/render_assets.sh flyover    # just the 36-frame loop
#
# Requires: Python 3.10+, a wgpu-capable GPU, cwebp + img2webp (brew install webp).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLS="$ROOT/tools/forge3d"
VENV="$TOOLS/.venv"
ASSETS="$ROOT/assets/forge3d"
STAGE="${1:-all}"

case "$STAGE" in
  hero|turntable|flyover|all) ;;
  *)
    echo "usage: $0 [hero|turntable|flyover|all]" >&2
    exit 2
    ;;
esac

PYTHON="${PYTHON:-python3}"

if [ ! -x "$VENV/bin/python" ]; then
  echo "[assets] creating venv at $VENV"
  "$PYTHON" -m venv "$VENV"
fi

"$VENV/bin/pip" install --quiet --upgrade pip
"$VENV/bin/pip" install --quiet -r "$TOOLS/requirements.txt"

"$VENV/bin/python" "$TOOLS/build_steppe_dem.py"
"$VENV/bin/python" "$TOOLS/render_origins.py" "$STAGE"

command -v cwebp >/dev/null || {
  echo "[assets] cwebp not found — brew install webp" >&2
  exit 1
}
command -v img2webp >/dev/null || {
  echo "[assets] img2webp not found — brew install webp" >&2
  exit 1
}

mkdir -p "$ASSETS"

echo "[assets] encoding hero"
cwebp -quiet -q 90 "$TOOLS/out/origins-hero.png" -o "$ASSETS/origins-hero.webp"

echo "[assets] encoding turntable"
for f in "$TOOLS"/out/turntable/turntable_*.png; do
  base="$(basename "$f" .png)"
  cwebp -quiet -q 88 "$f" -o "$ASSETS/$base.webp"
done

echo "[assets] encoding flyover"
img2webp -loop 0 -d 83 -lossy -q 82 \
  "$TOOLS"/out/flyover/flyover_*.png \
  -o "$ASSETS/origins-flyover.webp"

echo "[assets] done:"
ls -lh "$ASSETS"
