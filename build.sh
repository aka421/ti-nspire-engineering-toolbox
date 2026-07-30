#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
LUNA="$ROOT/tools/Luna/luna"
DIST="$ROOT/dist"
BUNDLE="$DIST/engineering_toolbox.lua"
OUTPUT="$DIST/engineering_toolbox.tns"

if [[ ! -x "$LUNA" ]]; then
  echo "Luna is not built yet. Run ./setup-luna.sh first." >&2
  exit 1
fi

mkdir -p "$DIST"

cat \
  "$ROOT/src/libraries/expression.lua" \
  "$ROOT/src/libraries/complex.lua" \
  "$ROOT/src/libraries/vectors.lua" \
  "$ROOT/src/libraries/coordinates.lua" \
  "$ROOT/src/ui/menu.lua" \
  "$ROOT/src/ui/calculator.lua" \
  "$ROOT/src/calculators/complex.lua" \
  "$ROOT/src/calculators/circuits.lua" \
  "$ROOT/src/calculators/electromagnetics.lua" \
  "$ROOT/src/calculators/coordinates.lua" \
  "$ROOT/src/main.lua" \
  > "$BUNDLE"

"$LUNA" "$BUNDLE" "$OUTPUT"
echo "Built: dist/engineering_toolbox.tns"
