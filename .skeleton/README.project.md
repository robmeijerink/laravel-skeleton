# __NAME__

Laravel on PostgreSQL, built from [laravel-skeleton](https://github.com/robmeijerink/laravel-skeleton). Everything runs in Docker via [Task](https://taskfile.dev); PHP, Composer and Bun on the host are not used.

## Commands

| Command | What it does |
| :--- | :--- |
| `task dev` | App, queue worker, logs and Vite with hot reloading on http://localhost:8000 |
| `task check` | Rector, Pint, Larastan (max), Pest and type coverage: the "am I done?" command |
| `task test -- --filter=Name` | Pest |
| `task artisan -- <args>`, `task composer -- <args>`, `task bun -- <args>` | Any other command |
| `task agent` | Claude Code in a sandbox (see `docs/decisions/002-agent-sandbox.md`) |
| `task build` | Production image (FrankenPHP) |
| `task build:dev` | Rebuild the dev image with the newest Composer, Bun and installer |

## First run

```bash
task dev     # first run builds the image; vendor/ and node_modules/ were installed by `task init`
```

`.env` is a symlink to `.secrets/.env`, which the agent sandbox cannot read. Tests use the committed `.env.testing` (fake values) and the separate `testing` database.

## Keeping it current

Dependabot proposes updates weekly (including the PHP minor in both Dockerfiles); minor and patch PRs merge by themselves once CI is green. See `docs/decisions/004-stack-choices.md`.
