#!/usr/bin/env bash
# Architecture rules that tools can't see. Run from the repo root (check.sh does).
set -euo pipefail
cd "$(dirname "$0")/.."

MAX_LINES=300
fail=0

# 1. Small modules: no file grows past MAX_LINES; split it into a folder instead.
while IFS= read -r file; do
	lines=$(wc -l < "$file")
	if [ "$lines" -gt "$MAX_LINES" ]; then
		echo "too long ($lines > $MAX_LINES lines): $file"
		fail=1
	fi
done < <(find src -name '*.luau')

# 2. Exactly one server and one client entry point; everything else is a ModuleScript.
scripts=$(find src -name '*.server.luau' -o -name '*.client.luau' | sort)
expected=$'src/ServerScriptService/Boot.server.luau\nsrc/StarterPlayer/StarterPlayerScripts/Boot.client.luau'
if [ "$scripts" != "$expected" ]; then
	echo "only the two Boot scripts may be Scripts/LocalScripts, found:"
	echo "$scripts"
	fail=1
fi

# 3. Shared code never reaches into Client or Server.
if grep -rnE 'ReplicatedStorage\.Client|ServerScriptService' src/ReplicatedStorage/Shared; then
	echo "Shared must not require Client or ServerScriptService"
	fail=1
fi

# 4. Remotes are created only by Net.
if grep -rnE 'Instance\.new\("(Remote|UnreliableRemote)' src --include='*.luau' | grep -v 'Shared/Net/'; then
	echo "create remotes only through Shared/Net/Remotes"
	fail=1
fi

exit "$fail"
