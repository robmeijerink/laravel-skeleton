# __NAME__

A Laravel application on PostgreSQL, created from [laravel-skeleton](https://github.com/robmeijerink/laravel-skeleton). Everything runs in Docker through [Task](https://taskfile.dev), so you only need Docker and Task on your machine.

## Getting started

```bash
task dev
```

This starts Laravel, a queue worker, the log viewer and Vite with hot reloading. Open http://localhost:8000. The first run takes a moment while Docker builds the image.

Run `task` on its own for a searchable menu of all commands (needs [fzf](https://github.com/junegunn/fzf)).

## Commands

Arguments for the underlying tool go after `--`.

| Command | What it does |
| :--- | :--- |
| `task dev` | Start the app at http://localhost:8000 |
| `task down` | Stop the containers |
| `task check` | Run Rector, Pint, the frontend checks, Larastan, the tests and the type-coverage check. Run this before every commit. |
| `task test` | Run the tests, for example `task test -- --filter=UserTest` |
| `task fmt` | Format the code with Pint |
| `task artisan -- <command>` | Run Artisan, for example `task artisan -- make:model Post -m` |
| `task composer -- <command>` | Run Composer, for example `task composer -- require spatie/laravel-data` |
| `task bun -- <command>` | Run Bun, for example `task bun -- add -d vitest` |
| `task shell` | Open a shell in the app container |
| `task agent` | Start Claude Code in the sandbox; Claude's own flags go after `--` |
| `task agent:update` | Rebuild the sandbox with the latest Claude Code |
| `task build` | Build the production image |
| `task build:dev` | Rebuild the development image with the latest Composer and Bun |

## Development environment

| Service | Address | |
| :--- | :--- | :--- |
| Laravel | http://localhost:8000 | The app, a queue worker, the log viewer and Vite, together |
| Vite | http://localhost:5173 | Hot reloading for the frontend |
| PostgreSQL | `postgres:5432`, from the containers only | Database `app`, user `app`, password `secret`. Open a database shell with `task artisan -- db`. |

Mailpit (http://localhost:8025) and Redis (`localhost:6379`) are there too if you chose them during setup. All ports are only reachable from your own machine; change them in `.devcontainer/docker-compose.yml`. PostgreSQL is not published, so it never clashes with another project's database; add a `ports:` entry to the `postgres` service to connect a database tool.

**Hot reload.** Vite checks for changed files every 300 ms instead of waiting for file events, which do not always reach the container. Change the interval with `CHOKIDAR_INTERVAL` in `.devcontainer/docker-compose.yml`.

**VS Code.** Choose *Reopen in Container* to work inside the app container, with the Intelephense and Tailwind CSS extensions installed.

**Linux.** The app container runs as root, so files it creates (for example with `task artisan -- make:model`) are owned by root.

## Code quality

`task check` runs these in order and stops at the first failure:

1. **Rector** removes dead code, simplifies code, adds missing types and applies PHP upgrades (`rector.php`).
2. **Pint** formats the code with the Laravel preset.
3. **Frontend checks**, if the project has them: the starter kit's lint and format check (`bun run check:fix`) and the TypeScript check (`bun run types:check`).
4. **Larastan** analyses the code at level max, the strictest level (`phpstan.neon`). If the starter kit's code did not pass, it is listed in `phpstan-baseline.neon`; keep that list from growing.
5. **Pest** runs the tests, including the architecture rules in `tests/Unit/ArchTest.php`.
6. **Pest type coverage** checks that every parameter, return value and property has a type. The minimum is 100% (`test:types` in `composer.json`).

Rector, Pint and the frontend formatter change files; the other steps only report. CI runs the same steps but changes nothing, so it fails if any of them would still change something. `.prettierignore` keeps the frontend formatter away from the files that came with the template.

The steps are Composer scripts, so `task check`, the AI sandbox and CI share one definition: `composer qa` runs them all, `composer qa:ci` is the CI version, and `rector`, `fix`, `stan`, `test:unit` and `test:types` run one step each.

**Code coverage.** Run `task test -- --coverage` (or `composer test:coverage`) for a coverage report. No minimum is enforced; add `--min=<percentage>` to the `test:coverage` script and to `qa` if you want one.

If the starter kit contained code that could not be typed automatically, that line is marked with `// @pest-ignore-type`. New code gets no such exceptions.

[Essentials](https://github.com/nunomaduro/essentials) is also installed and changes some Laravel defaults:

- Models are strict (`Model::shouldBeStrict()`): reading an attribute that was not loaded, or filling one that is not fillable, throws an exception instead of failing silently. Relationships are eager loaded automatically, which prevents N+1 queries.
- Dates are immutable (`CarbonImmutable`).
- Tests cannot make real HTTP requests, and `sleep()` is faked.
- In production, generated URLs use HTTPS and destructive Artisan commands (such as `migrate:fresh`) are blocked.

To change any of these, publish the config with `task artisan -- vendor:publish --tag=essentials-config` and edit `config/essentials.php`.

## Configuration and secrets

`.env` is a link to `.secrets/.env`. Keep anything secret in `.secrets/`: the AI sandbox cannot read that folder, git ignores it, and it is left out of the production image.

Tests use the committed `.env.testing`, which contains only fake values, and run against a separate `testing` database. Running the tests never touches your development data.

Never run `php artisan config:cache` locally: it writes all your secrets in plain text to `bootstrap/cache/config.php`. If you did, undo it with `task artisan -- config:clear`.

## Working with AI agents

`AGENTS.md` tells agents (Claude Code, Codex, Cursor) how to work in this project; `CLAUDE.md` points to it. `.claude/settings.json` allows `task` and read-only git commands, asks before adding dependencies, and blocks direct `php`, `composer`, `bun`, `node` and `npm` calls.

`task agent` starts Claude Code in its own container. The first time, Claude asks whether you trust the folder and you log in with `/login`; both are kept between sessions. The sandbox:

- sees only this project, not your home folder or the Docker socket;
- cannot read `.secrets/`;
- cannot change git, the Taskfile, the Docker setup or the Claude Code settings, and cannot commit or push;
- has its own copies of `vendor/` and `node_modules/`;
- runs as a non-root user with all Linux capabilities removed;
- uses only the `testing` database, through `.env.testing`.

Inside the sandbox, `task check`, `task test`, `task fmt`, `task artisan`, `task composer` and `task bun` work as on your machine.

The code an agent writes still runs on your machine when you run `task check` or `task dev`, and the sandbox has open network access. Review its changes before you run them. The [sandbox decision record](docs/decisions/002-agent-sandbox.md) explains the limits.

**Personal skills and instructions.** The sandbox mounts the Docker volumes `ai-skills-provider` (as Claude's skills folder) and `ai-instructions-provider` (at `/opt/ai-instructions`), read-only. Link them to a folder on your machine to use them:

```bash
docker volume rm ai-skills-provider
docker volume create --driver local --opt type=none --opt o=bind --opt device=$HOME/ai/skills ai-skills-provider
```

**Your own tasks.** Put machine-specific tasks in `Taskfile.local.yml`. Git ignores it.

## Production

`task build` creates an image based on [FrankenPHP](https://frankenphp.dev) that serves the app on port 8080. It runs as a non-root user and has a health check on `/up`.

- **Configuration.** Pass settings as environment variables when you start the container; nothing secret is stored in the image. You need at least `APP_KEY` (generate one with `task artisan -- key:generate --show`), `APP_ENV=production`, `APP_URL` and the `DB_` variables.
- **Deploying.** On every release, run `php artisan migrate --force` and `php artisan optimize` in the container.
- **HTTPS.** Put a reverse proxy or load balancer in front of the container. The image serves plain HTTP, because it runs as a non-root user and cannot open ports 80 and 443.
- **Background work.** The image runs only the web server. For queues and scheduled tasks, start the same image with `php artisan queue:work` or `php artisan schedule:work` as the command.
- **Files.** Mount a volume at `/app/storage`, or store uploads in object storage.
- **Server-side rendering.** Inertia SSR is not included, because the image contains no JavaScript runtime. The app works without it.

## Keeping it up to date

Dependabot checks every week for updates to PHP, the Composer and Bun packages, and the GitHub Actions. A new PHP version arrives as a pull request for the development image only: Dependabot cannot read the FrankenPHP tag of the production image. CI then fails with a message that tells you which line to change in `Dockerfile`; change it in the pull request and the checks go green. Minor and patch updates merge themselves once CI passes; major updates and failing updates wait for you.

For this to work, set up the repository once:

1. Go to **Settings → General** and enable **Allow auto-merge**.
2. Go to **Settings → Rules → Rulesets**, create a branch ruleset for the default branch, enable **Require status checks to pass**, and add **Format, Analyse & Test** and **Build Docker Image**. The checks appear in the list after CI has run once.
3. In the same ruleset, enable **Block force pushes** and **Restrict deletions**, and add **Repository admin** to the bypass list.

Without a ruleset, nothing is merged automatically.

## Design decisions

The reasoning behind the setup is in [`docs/decisions/`](docs/decisions/). Add a new record there for each architectural decision you make.
