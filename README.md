# Laravel Skeleton

A container-first template for Laravel with agentic AI (Claude Code, Codex, Cursor, ...). It contains **no Laravel code**: `task init` runs the newest official installer and starter kit, so a project started in five years gets the versions of that day. See [003](docs/decisions/003-template-and-init.md).

## Features

* **Choose your stack:** official React, Vue or Livewire kit, the blank Inertia kit (`--no-auth`), plain Blade + Vite, or a Vite React/Vue SPA. Add-ons: Filament, Mailpit, Redis.
* **Container-first:** PHP, Composer and Bun run in Docker; nothing is installed on the host. PostgreSQL in dev, tests and CI.
* **Bun** instead of Node/pnpm for Vite and the frontend packages.
* **Strict by default:** Pest with arch tests, type coverage (100%) and the PHPStan plugin; Larastan at max level; Rector; Pint; Essentials. One command: `task check`.
* **Agent-ready:** lean `AGENTS.md`, pre-approved permissions, and a hardened sandbox (`task agent`) with secrets kept out of reach. See [001](docs/decisions/001-agentic-development-setup.md) and [002](docs/decisions/002-agent-sandbox.md).
* **Production image:** FrankenPHP (classic mode), multi-stage, non-root.
* **Low maintenance:** Dependabot and auto-merge for green PRs; a weekly smoke test builds every variant. See [004](docs/decisions/004-stack-choices.md).

## Prerequisites

| Tool | Requirement |
| :--- | :--- |
| [Docker](https://docs.docker.com/get-docker/) with Compose and Buildx | Required |
| [Task](https://taskfile.dev/installation/) | Required |
| [gum](https://github.com/charmbracelet/gum) | For the wizard (flags work without it) |
| [fzf](https://github.com/junegunn/fzf) | Optional (the interactive Task menu) |

Keep the project under your home folder, which Docker mounts by default. A folder outside Docker's shared paths (Docker Desktop: *Settings → Resources → File sharing*; Colima: `mounts` in `colima.yaml`) shows up empty in the containers: `task init` then fails with `No such file or directory` for `.skeleton/install.sh`.

## Production

`task build` builds the image: FrankenPHP in classic mode, one process serving HTTP on port 8080 (put a TLS proxy in front, or set `SERVER_NAME` to your domain for automatic HTTPS).

* **Configuration comes from the environment at runtime**, never from the image: at least `APP_KEY` (`php artisan key:generate --show`), `APP_ENV=production`, `APP_URL` and the `DB_*` variables.
* **On every deploy** run `php artisan migrate --force` and `php artisan optimize` (this is the place for config and route caching; never locally).
* **Not in the image:** a queue worker and the scheduler. Run the same image with another command: `php artisan queue:work` and `php artisan schedule:work`. Inertia **SSR** is not available either, because the image has no Bun or Node; the starter kits work client-side without it.
* **Storage:** mount a volume at `/app/storage`, or use an object store, for uploads and logs.
* **Health:** the image has a healthcheck on Laravel's `/up` route.

## Getting Started

1. Click **Use this template** on GitHub, clone the new repository.
2. `task init` (wizard), or with flags: `task init -- --vue --no-auth --filament --mailpit`. `task init -- --help` lists them.
3. `task check`, then `task dev` (http://localhost:8000).
4. Update `.github/CODEOWNERS`. Enable *Allow auto-merge* (*Settings → General*) and add a branch ruleset on `main` that requires status checks (*Settings → Rules*), see [004](docs/decisions/004-stack-choices.md):
   * **In the project:** the checks **Format, Analyse & Test** and **Build Docker Image** (from `ci.yml`, which `init` puts in place).
   * **In the template repo itself:** the six jobs of *Skeleton smoke test* (named after their flags, e.g. `--react --mailpit --redis`). The template has no `ci.yml`: there is no app to test until `init` has run.

`task init` replaces this README with a short project README and removes the template's `LICENSE` (MIT): choose your own for the project.

If `task init` fails halfway (a network hiccup in Composer, say), undo with `git restore . && git clean -fd` and run it again.
