# Changelog

## 0.1.0 - 2026-11-24

Initial release.

- `task init` creates a Laravel project from the latest installer, with a wizard or flags: the React, Vue and Livewire starter kits (with or without authentication), plain Blade, and React or Vue SPA stubs, with the add-ons Filament, Mailpit and Redis.
- Everything runs in Docker through Task: PHP 8.5, PostgreSQL 18 with a separate `testing` database, Pun for PHP packages, and Bun instead of Node. Hot reload works inside the container.
- `task check` runs [Pun](https://punphp.com) (formatting with Pint's rules, Rector's sets, and analysis at PHPStan level max with Larastan's checks), Oxlint and Oxfmt, the TypeScript check, Pest with arch tests in parallel, and 100% type and code coverage. Code of the starter kit that does not pass is recorded once at `init`, so new code starts without exceptions.
- laravel-data with generated TypeScript types for the React, Vue and SPA stacks, and PAO for compact tool output for agents.
- `AGENTS.md`, Claude Code permissions and `task agent`, which runs Claude Code in a sandbox container without access to secrets, git or the Docker setup.
- A production image on FrankenPHP, non-root with a health check.
- CI for generated projects, weekly Dependabot updates with automatic merging of minor and patch updates, and a smoke test that builds every stack of the template.
- Architecture decision records in `docs/decisions/`.
