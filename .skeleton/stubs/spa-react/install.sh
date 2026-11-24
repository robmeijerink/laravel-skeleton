#!/usr/bin/env bash
# Own stub: the official starter kits cover Inertia; this is a plain Vite React SPA on top of bare Laravel.
set -euo pipefail
bun add react react-dom
bun add -d @vitejs/plugin-react typescript @types/react @types/react-dom
rm -f vite.config.js resources/js/app.js resources/js/bootstrap.js resources/views/welcome.blade.php
rsync -a .skeleton/stubs/spa-react/files/ ./
# A typecheck script, so `composer qa` and CI check the TypeScript too
php -r '$f = "package.json"; $j = json_decode(file_get_contents($f), true); $j["scripts"]["types:check"] = "tsc --noEmit"; file_put_contents($f, json_encode($j, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\n");'
