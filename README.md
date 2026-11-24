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

The project must be in a directory Docker can mount (Docker Desktop: *Settings → Resources → File sharing*; Colima: `mounts` in `colima.yaml`).

## Getting Started

1. Click **Use this template** on GitHub, clone the new repository.
2. `task init` (wizard), or with flags: `task init -- --vue --no-auth --filament --mailpit`. `task init -- --help` lists them.
3. `task check`, then `task dev` (http://localhost:8000).
4. Update `.github/CODEOWNERS`; enable *Allow auto-merge* and require the CI checks on `main` (see [004](docs/decisions/004-stack-choices.md)).

`task init` replaces this README with a short project README.
