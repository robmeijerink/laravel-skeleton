#!/usr/bin/env bash
# Own stub: the official starter kits cover Inertia; this is a plain Vite Vue SPA on top of bare Laravel.
set -euo pipefail
bun add vue
# TypeScript 5, like Laravel's own Vue starter kit: vue-tsc does not support the native TypeScript 7 yet
# (checked 2026-11-24). The smoke test shows when this can go; Dependabot proposes the major bump.
bun add -d @vitejs/plugin-vue typescript@^5 vue-tsc
rm -f vite.config.js resources/js/app.js resources/js/bootstrap.js resources/views/welcome.blade.php
rsync -a .skeleton/stubs/spa-vue/files/ ./
# A typecheck script, so `composer qa` and CI check the TypeScript too
php -r '$f = "package.json"; $j = json_decode(file_get_contents($f), true); $j["scripts"]["types:check"] = "vue-tsc --noEmit"; file_put_contents($f, json_encode($j, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\n");'
