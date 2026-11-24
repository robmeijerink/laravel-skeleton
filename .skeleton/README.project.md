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

## Production

`task build` builds the image: FrankenPHP in classic mode, one process serving HTTP on port 8080 (put a TLS proxy in front, or set `SERVER_NAME` to your domain for automatic HTTPS).

* **Configuration comes from the environment at runtime**, never from the image: at least `APP_KEY` (`php artisan key:generate --show`), `APP_ENV=production`, `APP_URL` and the `DB_*` variables.
* **On every deploy** run `php artisan migrate --force` and `php artisan optimize` (this is the place for config and route caching; never locally).
* **Not in the image:** a queue worker and the scheduler. Run the same image with another command: `php artisan queue:work` and `php artisan schedule:work`. Inertia **SSR** is not available either, because the image has no Bun or Node; the starter kits work client-side without it.
* **Storage:** mount a volume at `/app/storage`, or use an object store, for uploads and logs.
* **Health:** the image has a healthcheck on Laravel's `/up` route.

## Keeping it current

Dependabot proposes updates weekly (including the PHP minor in both Dockerfiles); minor and patch PRs merge by themselves once CI is green. See `docs/decisions/004-stack-choices.md`.
