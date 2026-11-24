#!/usr/bin/env bash
# Own stub: the official starter kits cover Inertia; this is a plain Vite React SPA on top of bare Laravel.
set -euo pipefail
bun add react react-dom
bun add -d @vitejs/plugin-react typescript @types/react @types/react-dom
rm -f vite.config.js resources/js/app.js resources/js/bootstrap.js resources/views/welcome.blade.php
rsync -a .skeleton/stubs/spa-react/files/ ./
