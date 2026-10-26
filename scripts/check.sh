#!/usr/bin/env bash
# Everything CI runs: format, lint, build. Run from the repo root.
set -euo pipefail
cd "$(dirname "$0")/.."

stylua --check src
selene src
mkdir -p build
rojo build default.project.json -o build/Shuffle.rbxl
echo "OK"
