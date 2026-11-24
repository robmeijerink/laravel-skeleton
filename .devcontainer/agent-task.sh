#!/bin/sh
# `task` inside the agent sandbox, which has no Docker: runs the same commands as the tasks in
# Taskfile.yaml, so AGENTS.md and .claude/settings.json hold in both places. Keep it in sync with
# Taskfile.yaml. Mounted read-only at /usr/local/bin/task (see docker-compose.yml).
set -e
cmd="$1"
if [ $# -gt 0 ]; then shift; fi
if [ "$1" = "--" ]; then shift; fi

# The sandbox has its own vendor/ and node_modules volumes, which start empty
deps() {
  [ -f vendor/autoload.php ] || pun install
  [ -f package.json ] && [ ! -d node_modules/.bin ] && bun install --frozen-lockfile || true
}

case "$cmd" in
  check) deps && composer qa ;;
  test) deps && exec vendor/bin/pest "$@" ;;
  fmt) deps && exec vendor/bin/pun format "$@" ;;
  artisan) deps && exec php artisan "$@" ;;
  # The project's locked Pun once vendor/ exists; the image's Pun before that
  pun) if [ -x vendor/bin/pun ]; then exec vendor/bin/pun "$@"; else exec pun "$@"; fi ;;
  composer) exec composer "$@" ;;
  bun) exec bun "$@" ;;
  *) echo "task '$cmd' is not available in the agent sandbox (available: check, test, fmt, artisan, pun, composer, bun)" >&2; exit 1 ;;
esac
