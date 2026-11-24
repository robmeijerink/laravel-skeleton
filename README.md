# Laravel Skeleton

A GitHub template for starting Laravel projects that run entirely in Docker and are set up for working with AI agents such as Claude Code.

The template contains no Laravel code. When you create a project, `task init` runs the official Laravel installer, so you always start from the latest Laravel, starter kit and packages, whether that is today or five years from now. Around that it adds a strict quality setup, a sandbox for AI agents, a production image, and automatic dependency updates.

## Contents

- [Requirements](#requirements)
- [Quick start](#quick-start)
- [Choosing a stack](#choosing-a-stack)
- [What `task init` does](#what-task-init-does)
- [What's included](#whats-included)
- [Commands](#commands)
- [Development environment](#development-environment)
- [Configuration and secrets](#configuration-and-secrets)
- [Working with AI agents](#working-with-ai-agents)
- [Production](#production)
- [Keeping projects up to date](#keeping-projects-up-to-date)
- [Customising](#customising)
- [What's not included](#whats-not-included)
- [Troubleshooting](#troubleshooting)
- [Design decisions](#design-decisions)

## Requirements

| Tool | |
| :--- | :--- |
| [Docker](https://docs.docker.com/get-docker/) with Compose and Buildx | Required. Docker Desktop includes both; with Colima, install `docker-buildx` as well. |
| [Task](https://taskfile.dev/installation/) | Required. Runs every command in this project. |
| [gum](https://github.com/charmbracelet/gum) | Optional. Needed for the interactive questions of `task init`; flags work without it. |
| [fzf](https://github.com/junegunn/fzf) | Optional. Needed for the searchable command menu (`task` without arguments). |

PHP, Pun, Composer, Node and Bun are not needed on your machine. Keep projects in a folder under your home directory, which Docker can access by default.

## Quick start

1. Click **Use this template** on GitHub and clone the new repository.
2. Run `task init` and answer the questions.
3. Run `task check` to confirm everything works.
4. Run `task dev` and open http://localhost:8000.
5. Set up the GitHub repository as described in [Keeping projects up to date](#keeping-projects-up-to-date).

`task init` takes a few minutes. When it finishes, this README is replaced by a shorter README for your project.

## Choosing a stack

`task init` asks which stack and add-ons you want. Use the arrow keys and Enter to choose; in the add-on list, press `x` to select an item. You can also skip the questions and pass flags:

```bash
task init -- --vue --no-auth --filament --mailpit
```

Pick one stack:

| Flag | What you get |
| :--- | :--- |
| `--react` | The official [React starter kit](https://laravel.com/docs/starter-kits): Inertia, TypeScript and Tailwind, with login, registration, password reset, email verification and two-factor authentication |
| `--vue` | The official Vue starter kit: Inertia, TypeScript and Tailwind, with authentication |
| `--livewire` | The official Livewire starter kit, with authentication |
| `--blade` | Plain Laravel with Blade templates, Vite and Tailwind, without authentication |
| `--spa-react` | Laravel plus a single-page React app built with Vite. Laravel serves the app shell and an example `/api/ping` route. |
| `--spa-vue` | The same, with Vue |

Add any of these options:

| Flag | What it does |
| :--- | :--- |
| `--no-auth` | Leaves out authentication. With `--react` or `--vue` this installs Laravel's minimal Inertia kit. |
| `--filament` | Adds a [Filament](https://filamentphp.com) admin panel at `/admin`, next to the frontend you chose |
| `--mailpit` | Adds [Mailpit](https://mailpit.axllent.org), which catches all outgoing mail; view it at http://localhost:8025 |
| `--redis` | Adds Redis and uses it for the cache, sessions and queues |
| `--name=<name>` | Sets the project name (default: the folder name) |
| `--dry-run` | Shows what would be installed, without installing anything |
| `--help` | Lists all flags |

The React, Vue and Livewire kits are maintained by Laravel and installed in their latest version. The two SPA variants are small starting points kept in this template.

## What `task init` does

1. Runs the latest Laravel installer in a container, with PostgreSQL, Pest and Bun, and the stack you chose.
2. Merges the new app into the repository. Files from the template, such as this setup and the agent configuration, are kept.
3. Connects the app to the PostgreSQL container and creates a separate `testing` database configuration with fake values in `.env.testing`.
4. Replaces Pint with [Pun](https://punphp.com), installs the Pest plugins and [Essentials](https://github.com/nunomaduro/essentials), writes `pun.toml`, and adds the Composer scripts that `task check` uses.
5. Installs the add-ons you chose and removes the services you did not choose from the Docker setup.
6. Configures Vite to work inside the container, and makes the Inertia kits' tests pass while `task dev` is running.
7. Moves `.env` to `.secrets/.env` and puts a link in its place, so the AI sandbox cannot read it.
8. Lets Pun and the frontend formatter tidy the installer's code. What still fails the strictest checks is recorded once: a Pun baseline, and line markers for type and code coverage. Your own code starts with no exceptions.
9. Removes everything that was only needed for setup: the `.skeleton/` folder, the `init` task, the template's smoke test, release workflow and changelog, this README and the MIT license.

If something goes wrong halfway, `init` stops and tells you how to undo the partial install.

## What's included

### Runtime

| | |
| :--- | :--- |
| **PHP 8.5** | In a Docker image with Pun, Composer and the extensions `pdo_pgsql`, `intl`, `zip`, `bcmath`, `pcntl`, `redis` and `opcache`. The PHP version is the only version that is pinned; Dependabot proposes upgrades. |
| **PostgreSQL 18** | For development and tests. Tests use a separate `testing` database, so they never touch your development data. |
| **Bun** | Replaces Node and npm: installs the frontend packages and runs Vite. |
| **Redis** | Optional, via `--redis` |
| **Mailpit** | Optional, via `--mailpit` |

### Code quality

`task check` runs these tools in one go. It fixes what it can (Pun and the frontend formatter change files) and fails on the rest.

| Tool | Setting |
| :--- | :--- |
| [Pun](https://punphp.com) | One tool, configured in `pun.toml`, that formats like Pint (Laravel preset), lints with Rector's dead-code, code-quality, type-declaration and PHP-upgrade sets, and analyses like PHPStan at **level max**, the strictest level, with Larastan's and Carbon's checks. It also installs the Composer packages. See [the decision record](docs/decisions/005-pun.md) for what it does not do yet. |
| [Pest](https://pestphp.com) | Test framework, with the arch and type-coverage plugins. Tests run in parallel, each process with its own copy of the testing database. |
| Pest arch tests | `tests/Unit/ArchTest.php`, with the `php` and `security` presets. Add your own rules there. |
| Pest type coverage | Minimum **100%**: every parameter, return value and property must have a type |
| [PAO](https://github.com/laravel/pao) | When an AI agent runs the tests or Artisan, the output becomes compact JSON instead of progress bars and colours, which saves the agent tokens. Pun does the same for its own output. Unchanged when you run them yourself. |
| Frontend lint and format | [Oxlint](https://oxc.rs) and Oxfmt for every stack with JavaScript: the React and Vue kits run them through Vite+, the other stacks directly (style in `.oxfmtrc.json`: single quotes, 4 spaces) |
| TypeScript | With `--react`, `--vue`, `--spa-react` and `--spa-vue`: a full typecheck with `tsc` or `vue-tsc` (`bun run types:check`) |
| Code coverage | Minimum **100%**, measured with pcov: every line of your code needs a test. Lines of the starter kit that its own tests don't reach are excluded once, with PHPUnit's `@codeCoverageIgnore` markers. |
| [Essentials](https://github.com/nunomaduro/essentials) | Stricter Laravel defaults: strict models, automatic eager loading, immutable dates, no real HTTP requests or sleeps in tests, and in production HTTPS URLs and no destructive Artisan commands |

### Typed data (React, Vue and the SPAs)

| | |
| :--- | :--- |
| [laravel-data](https://spatie.be/docs/laravel-data) | Typed data objects for requests, responses and Inertia props |
| [TypeScript Transformer](https://github.com/spatie/laravel-typescript-transformer) | Turns every class in `app/` marked `#[TypeScript]` (data objects, enums) into a TypeScript type in `resources/js/generated/generated.d.ts`. `task check` regenerates the file; CI fails when the committed file is out of date. |

### Working with AI agents

| | |
| :--- | :--- |
| `AGENTS.md` | Short instructions for any agent (Claude Code, Codex, Cursor): which commands to use and the house rules. `CLAUDE.md` points to it. |
| `.claude/settings.json` | Permissions for Claude Code: `task` and read-only git commands are allowed, adding dependencies asks first, and direct `php`, `pun`, `composer`, `bun`, `node` and `npm` calls are blocked. |
| `task agent` | Runs Claude Code in a sandbox container. See [Working with AI agents](#working-with-ai-agents). |

### Infrastructure

| | |
| :--- | :--- |
| `Taskfile.yaml` | Every command, so you never need PHP or Bun on your machine |
| `.devcontainer/` | The Docker setup: the development image, Docker Compose and a VS Code Dev Container configuration |
| `Dockerfile` | Production image on [FrankenPHP](https://frankenphp.dev): non-root, with a health check |
| `Dockerfile.dev-agent` | The image for the AI sandbox |
| `.prettierignore` | Keeps the starter kits' frontend formatter away from the template's own files |
| `.github/workflows/` | CI for the project and automatic merging of Dependabot updates |
| `.github/dependabot.yml` | Weekly updates for PHP, Composer and Bun packages and GitHub Actions |
| `docs/decisions/` | Architecture decision records that explain the choices in this template |

## Commands

Run `task` without arguments for a searchable menu (needs fzf). Arguments for the underlying tool go after `--`.

| Command | What it does |
| :--- | :--- |
| `task init` | Create the Laravel app (only in the template; removed afterwards) |
| `task dev` | Start Laravel, a queue worker, the log viewer and Vite with hot reloading on http://localhost:8000 |
| `task down` | Stop the containers |
| `task check` | Run Pun (format, lint, analysis), the frontend checks, the tests and the type-coverage check. Run this before every commit. |
| `task test` | Run the tests, for example `task test -- --filter=UserTest` |
| `task fmt` | Format the code with Pun |
| `task artisan -- <command>` | Run Artisan, for example `task artisan -- make:model Post -m` |
| `task pun -- <command>` | Run Pun, for example `task pun -- require spatie/laravel-data` to add a package |
| `task composer -- <command>` | Run a Composer script or command, for example `task composer -- qa` |
| `task bun -- <command>` | Run Bun, for example `task bun -- add -d vitest` |
| `task shell` | Open a shell in the app container |
| `task agent` | Start Claude Code in the sandbox; Claude's own flags go after `--` |
| `task agent:update` | Rebuild the sandbox with the latest Claude Code |
| `task build` | Build the production image, tagged with the folder name |
| `task build:dev` | Rebuild the development image with the latest Composer, Pun, Bun and Laravel installer |

The quality checks are also Composer scripts, so `task check`, the sandbox and CI all run the same definition:

| Script | What it runs |
| :--- | :--- |
| `composer qa` | Everything `task check` runs (the tests run once, with coverage) |
| `composer qa:ci` | The same, but Pun and the frontend formatter only report instead of changing files (used by CI) |
| `composer pun`, `test:unit`, `test:types` | Pun (`pun check --fix`), the tests without coverage, and the type-coverage check on their own |
| `composer test:coverage` | The tests with coverage; fails below 100% |
| `composer types:generate` | Regenerate the TypeScript types from PHP (React, Vue and the SPAs) |

## Development environment

`task dev` starts these containers. All ports are only reachable from your own machine.

| Service | Address | |
| :--- | :--- | :--- |
| Laravel | http://localhost:8000 | `php artisan serve`, the queue worker, the log viewer and Vite, together |
| Vite | http://localhost:5173 | Hot reloading for the frontend |
| PostgreSQL | `postgres:5432`, from the containers only | Database `app`, user `app`, password `secret`. Open a database shell with `task artisan -- db`. |
| Mailpit | http://localhost:8025 | Only with `--mailpit` |
| Redis | `localhost:6379` | Only with `--redis` |

PostgreSQL is not published on your machine, so it never clashes with the database of another project. To connect a database tool, add a `ports:` entry to the `postgres` service in `.devcontainer/docker-compose.yml`.

The Composer, Pun and Bun download caches are shared between all projects in the Docker volumes `php_composer` (Pun's store is in its `pun` folder) and `bun_cache`. Remove them with `docker volume rm php_composer bun_cache` to start fresh.

**Hot reload.** Vite checks for changed files every 300 ms instead of waiting for file events, because file events from your editor do not always reach the container (they do not on macOS with Colima). Change the interval with `CHOKIDAR_INTERVAL` in `.devcontainer/docker-compose.yml`.

**VS Code.** Open the folder and choose *Reopen in Container* to work inside the app container, with the Intelephense and Tailwind CSS extensions installed.

**Linux.** The app container runs as root, so files it creates (for example with `task artisan -- make:model`) are owned by root. On macOS this does not apply.

## Configuration and secrets

`.env` is a link to `.secrets/.env`. Keep anything secret in `.secrets/`: the AI sandbox cannot read that folder, git ignores it, and it is left out of the production image.

Tests use the committed `.env.testing`, which contains only fake values, including a fake `APP_KEY`.

Never run `php artisan config:cache` locally: it writes all your secrets in plain text to `bootstrap/cache/config.php`. If you did, undo it with `task artisan -- config:clear`.

## Working with AI agents

`task agent` starts Claude Code in its own container. The first time, Claude asks whether you trust the folder and you log in with `/login`; both are kept between sessions and rebuilds.

The sandbox:

- sees only this project, not your home folder or the Docker socket;
- cannot read `.secrets/`, so it never sees your `.env`;
- cannot change git, the Taskfile, the Docker setup or the Claude Code settings, and cannot commit or push;
- has its own copies of `vendor/` and `node_modules/`, so it cannot change code that runs on your machine through Composer;
- runs as a non-root user with all Linux capabilities removed;
- uses the same PostgreSQL server as you, but only the `testing` database, through `.env.testing`.

Inside the sandbox, `task check`, `task test`, `task fmt`, `task artisan`, `task pun`, `task composer` and `task bun` work the same as on your machine.

The sandbox limits what an agent can reach, but the code it writes still runs on your machine when you run `task check` or `task dev`, and its network access is open. Review its changes before you run them. The [sandbox decision record](docs/decisions/002-agent-sandbox.md) explains the limits in detail.

**Personal skills and instructions.** The sandbox mounts two Docker volumes, read-only: `ai-skills-provider` as Claude's skills folder and `ai-instructions-provider` at `/opt/ai-instructions`. They are empty unless you link them to a folder on your machine, for example:

```bash
docker volume rm ai-skills-provider
docker volume create --driver local --opt type=none --opt o=bind --opt device=$HOME/ai/skills ai-skills-provider
```

**Your own tasks.** Put machine-specific tasks in `Taskfile.local.yml`. Git ignores it, and the sandbox can read it but not change it.

## Production

`task build` creates an image based on FrankenPHP that serves the app on port 8080. It runs as a non-root user and has a health check on Laravel's `/up` route.

- **Configuration.** Pass settings as environment variables when you start the container; nothing secret is stored in the image. You need at least `APP_KEY` (generate one with `task artisan -- key:generate --show`), `APP_ENV=production`, `APP_URL` and the `DB_` variables.
- **Deploying.** On every release, run `php artisan migrate --force` and `php artisan optimize` in the container.
- **HTTPS.** Put a reverse proxy or load balancer in front of the container. The image serves plain HTTP, because it runs as a non-root user and cannot open ports 80 and 443.
- **Background work.** The image runs only the web server. For queues and scheduled tasks, start the same image with `php artisan queue:work` or `php artisan schedule:work` as the command.
- **Files.** Mount a volume at `/app/storage`, or store uploads in object storage.

## Keeping projects up to date

Dependabot checks every week for updates to PHP, the Composer packages (including Pun itself), the Bun packages and the GitHub Actions. A new PHP version arrives as a pull request for the development image only: Dependabot cannot read the FrankenPHP tag of the production image. CI then fails with a message that tells you which line to change in `Dockerfile`; change it in the pull request and the checks go green.

A workflow merges minor and patch updates automatically once all required checks pass. Major updates, and any update with failing checks, stay open for you to review. To make this work, set up each repository once:

1. Go to **Settings → General** and enable **Allow auto-merge**.
2. Go to **Settings → Rules → Rulesets**, create a branch ruleset for the default branch, and enable **Require status checks to pass**. Add these checks:
   - In a project: **Format, Analyse & Test** and **Build Docker Image**.
   - In this template repository: the seven **Skeleton smoke test** jobs, named after their flags (for example `--react --mailpit --redis`).
3. In the same ruleset, enable **Block force pushes** and **Restrict deletions**, and add **Repository admin** to the bypass list so you can still push directly.

The checks only appear in the list after they have run once. Without a ruleset the workflow does not merge anything, because it would merge before the checks finish.

The template repository runs its smoke test on every push, on every pull request and every Monday. It creates a project for each stack and runs `task check` and the production build. Because the template always installs the latest versions, an upstream change can break it without any commit here; the smoke test is how you find out.

To release the template, add a section for the version to `CHANGELOG.md`, merge it to `main`, and push a tag such as `v0.1.0`. The release workflow checks that the tag is on `main`, waits for the smoke test of that commit to pass (it does not run it again), and creates a GitHub release with that section as its notes.

## Customising

- **Ports.** Change them in `.devcontainer/docker-compose.yml`.
- **PHP version.** Change the `FROM` line in both `.devcontainer/Dockerfile` and `Dockerfile`, or wait for Dependabot. CI checks that both use the same version.
- **Essentials.** Publish its configuration with `task artisan -- vendor:publish --tag=essentials-config` and switch features off in `config/essentials.php`.
- **Quality rules.** Pun's format, lint and analysis rules are in `pun.toml` ([reference](https://punphp.com/docs/configuration/pun-toml)), the architecture rules in `tests/Unit/ArchTest.php`.
- **Extra services.** Add them to `.devcontainer/docker-compose.yml`, for example a search engine or object storage.
- **The template itself.** Add-ons are small scripts in `.skeleton/addons/`, and the SPA starting points are in `.skeleton/stubs/`.

## What's not included

These are left out on purpose:

- **Node.js.** Bun runs Vite and the frontend tooling.
- **Inertia server-side rendering in production.** The production image contains no JavaScript runtime. The starter kits work without it.
- **A queue worker and scheduler in the production image.** Run them as separate containers from the same image.
- **Laravel Boost.** `AGENTS.md` is the single source of instructions for agents.
- **The installer's team and WorkOS options and the Svelte kit.** Add them yourself after `init` if you need them.

## Troubleshooting

**`task init` fails with `No such file or directory` for `.skeleton/install.sh`.**
Docker cannot see the project folder. Move it under your home directory, or share its location with Docker (Docker Desktop: *Settings → Resources → File sharing*; Colima: `mounts` in `colima.yaml`).

**`task init` fails halfway.**
This is usually a network problem while downloading packages. Undo the partial install and try again:

```bash
git restore . && git clean -fd
task init
```

**A port is already in use.**
Another project or program uses port 8000, 5173, 8025 or 6379. Stop it, or change the port in `.devcontainer/docker-compose.yml`.

**`task check` fails right after `init`.**
The latest Laravel release has probably changed something this template relies on. The smoke test in the template repository will show the same failure; fix it in `.skeleton/` there.

## Design decisions

The reasoning behind the setup is in [`docs/decisions/`](docs/decisions/):

- [Agentic development setup](docs/decisions/001-agentic-development-setup.md): `AGENTS.md`, `task check` and the guardrails
- [Agent sandbox](docs/decisions/002-agent-sandbox.md): what the sandbox protects against, and what it does not
- [Template and `task init`](docs/decisions/003-template-and-init.md): why the template contains no Laravel code, and which upstream quirks `init` works around
- [Stack choices](docs/decisions/004-stack-choices.md): PostgreSQL, Bun, FrankenPHP, and how versions stay current
- [Pun](docs/decisions/005-pun.md): why Pun replaces Pint, Rector, Larastan and most of Composer, and what it does not do yet

## License

MIT. `task init` removes this license from new projects, so you can choose your own.

---

This template is developed by [Solvalutions](https://solvalutions.nl) and [Rob Meijerink](https://robmeijerink.nl).

*&copy;&nbsp;2026 &mdash; Built by Rob Meijerink.*
