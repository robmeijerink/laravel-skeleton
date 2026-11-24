# Changelog

## 0.2.0 - 2026-11-24

[Pun](https://punphp.com) replaces Pint, Rector, Larastan and most of Composer.

- `task check` runs `pun check --fix`: formatting with Pint's Laravel rules, Rector's dead-code, code-quality, type-declaration and PHP sets, and analysis at PHPStan level max with Larastan's checks, all from one `pun.toml`. CI runs `pun check`, which changes nothing. Code of the starter kit that fails the analysis is recorded once in `pun-baseline.toml`.
- Pun installs the PHP packages in `task init`, CI, the agent sandbox and the production build. Add one with `task pun -- require <pkg>`. Composer stays for the Laravel installer, the Composer scripts and Dependabot.
- Each project locks its own Pun in `composer.lock`, so a new Pun arrives as a Dependabot PR.
- The starter kits' `lint`, `lint:check` and `types:check` scripts call Pun, so `composer test` keeps working.
- Claude Code asks before `task pun -- require`, `update` and `x`.
- Fix: the production image answered every request with a 500 when built from a Mac, because files that `task init` edits were readable only by their owner.
- Fix: when an agent ran `task init`, the type and code coverage markers were not set.
- The release workflow waits until the smoke test of the tagged commit has passed.

## 0.1.0 - 2026-11-24

Initial release.

- `task init` creates a Laravel project from the latest installer, with a wizard or flags: the React, Vue and Livewire starter kits (with or without authentication), plain Blade, and React or Vue SPA stubs, with the add-ons Filament, Mailpit and Redis.
- Everything runs in Docker through Task: PHP 8.5, PostgreSQL 18 with a separate `testing` database, and Bun instead of Node. Hot reload works inside the container.
- `task check` runs Rector, Pint, Oxlint and Oxfmt, the TypeScript check, Larastan at level max, Pest with arch tests in parallel, and 100% type and code coverage. Code of the starter kit that does not pass is recorded once at `init`, so new code starts without exceptions.
- laravel-data with generated TypeScript types for the React, Vue and SPA stacks, and PAO for compact tool output for agents.
- `AGENTS.md`, Claude Code permissions and `task agent`, which runs Claude Code in a sandbox container without access to secrets, git or the Docker setup.
- A production image on FrankenPHP, non-root with a health check.
- CI for generated projects, weekly Dependabot updates with automatic merging of minor and patch updates, and a smoke test that builds every stack of the template.
- Architecture decision records in `docs/decisions/`.
