#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$ROOT/tools"

if [[ ! -d "$ROOT/tools/Luna/.git" ]]; then
  git clone https://github.com/ndless-nspire/Luna.git "$ROOT/tools/Luna"
fi

cd "$ROOT/tools/Luna"
make

echo "Luna built successfully. Next run: ./build.sh"
