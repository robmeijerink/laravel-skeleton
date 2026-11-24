#!/usr/bin/env bash
# Own stub: the official starter kits cover Inertia; this is a plain Vite Vue SPA on top of bare Laravel.
set -euo pipefail
bun add vue
bun add -d @vitejs/plugin-vue typescript vue-tsc
rm -f vite.config.js resources/js/app.js resources/js/bootstrap.js resources/views/welcome.blade.php
rsync -a .skeleton/stubs/spa-vue/files/ ./
