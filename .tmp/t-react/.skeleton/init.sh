#!/usr/bin/env bash
# Host side of `task init`: asks the questions (gum) or takes flags, then runs install.sh in the app
# container. Deleted together with the rest of .skeleton/ once the app exists.
set -euo pipefail
cd "$(dirname "$0")/.."

usage() {
  cat <<'USAGE'
Usage: task init -- [stack] [options]

Stack (pick one; without flags a wizard asks):
  --react          Official React starter kit (Inertia)
  --vue            Official Vue starter kit (Inertia)
  --livewire       Official Livewire starter kit
  --blade          Plain Laravel with Blade and Vite, no starter kit
  --spa-react      Laravel with a Vite React SPA (own stub)
  --spa-vue        Laravel with a Vite Vue SPA (own stub)

Options:
  --no-auth        No authentication scaffolding (with --react/--vue: the minimal blank kit)
  --filament       Add Filament as an admin panel
  --mailpit        Add Mailpit (local mail catcher)
  --redis          Add Redis (cache, sessions, queue)
  --name=<name>    Project name (default: the folder name)
USAGE
}

STACK="" AUTH=1 FILAMENT=0 MAILPIT=0 REDIS=0 NAME=""
for arg in "$@"; do
  case "$arg" in
    --react|--vue|--livewire|--blade|--spa-react|--spa-vue) STACK="${arg#--}" ;;
    --no-auth) AUTH=0 ;;
    --filament) FILAMENT=1 ;;
    --mailpit) MAILPIT=1 ;;
    --redis) REDIS=1 ;;
    --name=*) NAME="${arg#--name=}" ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $arg" >&2; usage >&2; exit 1 ;;
  esac
done

if [ -f artisan ]; then echo "This project is already initialised (artisan exists)." >&2; exit 1; fi

if [ -z "$STACK" ]; then
  if ! command -v gum > /dev/null || [ ! -t 0 ]; then
    echo "No stack given and no interactive terminal with gum available." >&2; usage >&2; exit 1
  fi
  STACK=$(gum choose --header "Stack" \
    "react   Official React starter kit (Inertia)" \
    "vue     Official Vue starter kit (Inertia)" \
    "livewire  Official Livewire starter kit" \
    "blade   Plain Blade and Vite, no starter kit" \
    "spa-react  Vite React SPA (own stub)" \
    "spa-vue    Vite Vue SPA (own stub)" | awk '{print $1}')
  case "$STACK" in
    react|vue|livewire)
      gum confirm "Include authentication (login, register, settings)?" && AUTH=1 || AUTH=0 ;;
  esac
  ADDONS=$(gum choose --no-limit --header "Add-ons (space to select, enter to confirm)" Filament Mailpit Redis || true)
  case "$ADDONS" in *Filament*) FILAMENT=1 ;; esac
  case "$ADDONS" in *Mailpit*) MAILPIT=1 ;; esac
  case "$ADDONS" in *Redis*) REDIS=1 ;; esac
  [ -n "$NAME" ] || NAME=$(gum input --header "Project name" --value "$(basename "$PWD")")
fi

[ -n "$NAME" ] || NAME=$(basename "$PWD")
if ! echo "$NAME" | grep -Eq '^[a-zA-Z][a-zA-Z0-9_-]*$'; then
  echo "Invalid name '$NAME': letters, digits, - and _, starting with a letter" >&2; exit 1
fi

echo "Creating '$NAME': stack=$STACK auth=$AUTH filament=$FILAMENT mailpit=$MAILPIT redis=$REDIS"
# -T: no TTY, so it also works in CI; the installer runs with --no-interaction anyway
docker compose -f .devcontainer/docker-compose.yml run --rm -T --no-deps app \
  bash .skeleton/install.sh "$STACK" "$AUTH" "$FILAMENT" "$MAILPIT" "$REDIS" "$NAME"
