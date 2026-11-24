#!/usr/bin/env bash
# Filament admin panel: a separate panel at /admin, independent of the chosen frontend
set -euo pipefail
pun require filament/filament
php artisan filament:install --panels --no-interaction
