# 003: Template Plus `task init`, No Laravel Code in the Skeleton

## Context
The skeleton must install the newest Laravel, starter kits and packages five years from now, with almost no maintenance. A committed Laravel app would be outdated the day after it is committed, and every year of upgrades would land on the skeleton's maintainer.

## Decision
The repository contains **no Laravel code**: only the container setup, the agent sandbox, Taskfile, CI and `.skeleton/`. After "Use this template" on GitHub, `task init` runs the official `laravel/installer` (always the newest release) inside the dev container, in a temporary folder, because the installer refuses a non-empty directory and `--force` on the current one. The result is merged into the repo with `rsync --ignore-existing`, so skeleton files always win; `.gitignore` is merged line by line. Afterwards `init` deletes `.skeleton/`, the `init` task and the smoke-test workflow.

* **Stacks:** the official React, Vue and Livewire kits, their blank variants (`--no-auth`, the minimal Inertia setup), plain Blade with Vite, and two own SPA stubs (React, Vue). The kits are maintained by Laravel; only the SPA stubs (`.skeleton/stubs/`) are ours, and they stay as small as possible because they are the part that ages.
* **Add-ons** (Filament, Mailpit, Redis) are separate scripts in `.skeleton/addons/` that run after the base install. Compose services for add-ons are marked blocks that `init` keeps or drops.
* **Wizard and flags:** `task init` asks with gum; `task init -- --vue --no-auth --filament` skips the questions, so it is reproducible and usable by an agent and CI.
* **Boost is not installed:** it writes its own `AGENTS.md`/MCP config and expects PHP on the host; `AGENTS.md` here is the source of truth.

## Keeping the Template Honest
Nothing is pinned except the PHP minor ([004](004-stack-choices.md)), so the template can break without a commit (an installer flag is renamed, a kit changes its Vite config). `.github/workflows/skeleton-smoke.yml` runs `task init` for every variant and then `task check` and a production build, weekly and on pull requests. A failing run is the signal that `.skeleton/` needs a fix; `init` fails loudly (for example when it cannot patch the Vite config or `phpunit.xml`) instead of producing a half-configured project.

## Upstream Quirks `init` Works Around
Found while building the skeleton (2026-11); each one is a place the smoke test will show first if upstream changes:
* **The React kit's `install:features` hook calls `npm`** when it finds no lock file, and the image has no Node. `LARAVEL_INSTALLER_NO_NODE=1` makes the hook skip it; the installer then installs with Bun (`--bun`). If a kit stops honouring the flag, `init` fails with `npm: not found`.
* **`node_modules/` from the temporary folder is not merged** (native binaries and paths point at `/tmp`), so `init` runs `composer install` and `bun install` in the repo.
* **The kits ship their own `phpstan.neon` (level 7), `pint.json` and Composer scripts.** `init` keeps them and only raises the level to `max`; without a kit it writes its own.
* **The kits' `vite.config.ts` already has a `server:` block.** A second key would silently override the first, so `patch-vite.sh` extends the existing block (`host: '0.0.0.0'`, `hmr.host: 'localhost'`) and falls back to adding one.
* **`api.github.com` returned HTTP 504 for unauthenticated zipball downloads** in most Composer runs; `composer config --global use-github-api false` (in both images) downloads from github.com instead. `init` also retries Composer three times.
* **Type coverage must be 100, for new code too.** The React kit's PHP scored 98.2%: one closure parameter (`fn ($passkey)` in `SecurityController`) whose type comes from an Eloquent relation, which Rector cannot infer. `init` runs Rector (type declarations) and Pint, then marks what is still untyped with `// @pest-ignore-type` (the plugin reads that marker per line; `.skeleton/ignore-untyped.php` turns Pest's own report into markers) and prints each location as a `NOTE`. A lower `--min` would have let new untyped code slip through the gap, so that is only the last resort: if marking does not reach 100, `init` writes the measured value and says so. When upstream types that code, delete the marker.
