#!/usr/bin/env bash
# Vite runs in a container: it must listen on all interfaces, and the browser reaches HMR on localhost.
set -euo pipefail
cfg=$(ls vite.config.ts vite.config.js vite.config.mts vite.config.mjs 2> /dev/null | head -1 || true)
[ -n "$cfg" ] || { echo "No vite config found" >&2; exit 1; }
grep -q "0.0.0.0" "$cfg" && exit 0
settings="host: '0.0.0.0', hmr: { host: 'localhost' },"
if grep -q "^ *server: {" "$cfg"; then
  # A second `server:` key would silently override the first, so extend the kit's own block
  sed -i "0,/^\( *\)server: {/s//\1server: {\n\1    $settings/" "$cfg"
else
  sed -i "0,/defineConfig({/s//defineConfig({\n    server: { $settings },/" "$cfg"
fi
grep -q "0.0.0.0" "$cfg" || { echo "Could not patch $cfg; add server.host '0.0.0.0' yourself" >&2; exit 1; }
