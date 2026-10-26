#!/usr/bin/env bash
# Everything CI runs: format, lint, types, architecture rules, build. Run from anywhere.
set -euo pipefail
cd "$(dirname "$0")/.."

LUAU_LSP_VERSION="1.60.0"
if [ ! -f globalTypes.d.luau ]; then
	curl -sSL -o globalTypes.d.luau "https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/${LUAU_LSP_VERSION}/scripts/globalTypes.d.luau"
fi

echo "== format (stylua)"
stylua --check src

echo "== lint (selene)"
selene src

echo "== types (luau-lsp, strict)"
rojo sourcemap default.project.json -o sourcemap.json
luau-lsp analyze --sourcemap=sourcemap.json --definitions=globalTypes.d.luau --platform=roblox src

echo "== architecture rules (guard)"
./scripts/guard.sh

echo "== build (rojo)"
mkdir -p build
rojo build default.project.json -o build/Shuffle.rbxl

echo "All checks passed."
