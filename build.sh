#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
LUNA="$ROOT/tools/Luna/luna"

if [[ ! -x "$LUNA" ]]; then
  echo "Luna is not built yet. Run ./setup-luna.sh first." >&2
  exit 1
fi

mkdir -p "$ROOT/dist"
"$LUNA" "$ROOT/src/main.lua" "$ROOT/dist/engineering_toolbox.tns"
echo "Built: dist/engineering_toolbox.tns"
