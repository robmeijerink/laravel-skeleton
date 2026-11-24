# 002: Agent Sandbox

`task agent` runs Claude Code in a container, so an agent (even in auto-approve mode) can only reach this project and not the rest of the machine. The setup is the one from rust-skeleton, with Laravel specifics: PHP, Composer and Bun come from the project's own dev image.

## What the Sandbox Guarantees
* **Only the project is mounted.** No home directory, no Docker socket, no host `~/.claude`.
* **Secrets in `.secrets/` stay out.** `.env` is a symlink to `.secrets/.env` (done by `task init`); in the sandbox `.secrets/` is an empty, read-only `tmpfs`, so the symlink dangles. See [Secrets](#secrets).
* **Git, Task, Compose and Claude Code config are read-only.** `.git`, `Taskfile.yaml`, `Taskfile.local.yml`, `.devcontainer/` and `.claude/` are mounted read-only, so the agent can't plant a git hook, task, compose change or Claude Code hook that takes effect on the host. As a side effect the agent can't commit; `git status`, `git diff` and `git log` still work. You review and commit yourself.
* **Own volumes** for `vendor/`, `node_modules/`, the Composer and Bun caches and the Claude login. The host's `vendor/` is not writable by the agent: Composer scripts (`post-autoload-dump` runs `artisan package:discover`) and service providers in `vendor/` run on the host later.
* **Hardened container:** non-root user (on Linux with your own uid), all capabilities dropped, `no-new-privileges`, a process limit.
* **No credentials for git remotes**, so the agent can't push.
* **`php`, `composer`, `bun` and `node` are denied** in `.claude/settings.json`; the agent uses `task`, which in the sandbox is `.devcontainer/agent-task.sh` (check, test, fmt, artisan, composer, bun).

## What It Does Not Guarantee
* **Code the agent writes runs outside the sandbox later.** Tests, migrations, service providers, Composer scripts, `vite.config.ts` and the app itself run on the host side (the `app` container) via `task check`, `task dev` and the rest. Review the diff, especially `composer.json` scripts, new dependencies and `vite.config.ts`, before running `task` on the host.
* **Some project files run directly on the host.** Editors (Intelephense, PHPStan and ESLint integrations load project code), git hook managers (Husky, Lefthook, pre-commit keep hooks in project files, bypassing the read-only `.git`; mount their files read-only if you add one), `.envrc`/`mise.toml`, and agent instruction files (`AGENTS.md`, `CLAUDE.md`, `.mcp.json`). Check `git status --ignored` after a session.
* **The network is open.** The agent needs the Anthropic API, Packagist, the npm registry and the web, so what it can read can be sent out, for example after a prompt injection from a web page: source code, the git history, its login token, `storage/logs/`. The host and LAN are reachable too. Acceptable for a skeleton or open-source code; add an egress allowlist (a proxy that filters on domain name; IP allowlists break on CDN hosts) when the project holds valuable or confidential code.
* **The agent shares the Compose network with the app and Postgres.** On purpose: same database engine, same behaviour. Never load production dumps with customer data into the dev database: the agent can read them.

## Database
The agent uses the same Postgres server as you, not SQLite, which behaves differently. It runs with `APP_ENV=testing`, so artisan and Pest read the committed `.env.testing` (fake values, a fake `APP_KEY`) and the separate `testing` database (created by `.devcontainer/postgres-init.sql`, set in `phpunit.xml`). `RefreshDatabase` can therefore never wipe your dev data.

## Secrets
* **`.env` lives in `.secrets/`**, with a relative symlink at the root (the project is at `/app` in the containers). `phpdotenv` finds no file in the sandbox. Everywhere else it resolves as usual.
* **Fake values for the agent:** `.env.testing` is committed (`!.env.testing` in `.gitignore`). Anything non-secret the agent needs goes in `environment:` of the `agent` service.
* **Never run `config:cache` locally:** it writes every config value, secrets included, in plain text to `bootstrap/cache/config.php`. Remove it with `config:clear`.
* **`storage/logs/` is readable by the agent.** Don't log secrets. Optionally hide values on the error page with `debug_hide` in `config/app.php`.
* **`VITE_` variables are inlined in frontend bundles** and so readable.
* **The symlink is writable:** the agent can replace it with a `.env` of its own, which the host would then load. `task agent` warns about every `.env`, `.env.*` or `*.env` that is a regular file and not tracked by git.
* **Use dev keys only,** with low spending limits for anything that costs money when abused.

## Login
A Claude Pro/Max account has no API key. Log in once with `/login` in the sandbox; the token lives in the `agent_claude` volume, never in the repo. Revoke it by logging out in your account settings.

## Personal Skills and Instructions
Two empty-by-default volumes, `ai-skills-provider` (at `~/.claude/skills`) and `ai-instructions-provider` (at `/opt/ai-instructions`), both read-only. Bind them on your machine to a local folder (`docker volume create --driver local --opt type=none --opt o=bind --opt device=<folder> <name>`). No personal path or file ends up in the repo or an image. The agent can read them and the network is open: mount a dedicated folder, not a whole vault.

## Versions
`Dockerfile.dev-agent` is deliberately unpinned (latest Claude Code via the native installer; its auto-updater is off because an update would be lost when the container is recreated). Run `task agent:update` to get the latest. The base is the project's own dev image (`additional_contexts` in the compose file builds it first), so the agent has exactly the PHP, extensions, Composer and Bun of `app`.
