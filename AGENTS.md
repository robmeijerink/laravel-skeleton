# AGENTS.md

Laravel project on PostgreSQL. All tooling runs in Docker via Task; PHP, Composer and Bun on the host are not used.

## Commands

- `task check`: Rector, Pint and the frontend formatter (they edit files), the TypeScript check, Larastan (max level), Pest and type coverage (`composer qa`). Run it after every change; work is done only when it passes.
- `task test -- --filter=Name`: Pest, for the red/green loop on one test. Add `--coverage` for a coverage report.
- `task artisan -- <args>`, `task composer -- <args>`, `task bun -- <args>`: any other command, e.g. `task artisan -- make:model Post -m`.
- Don't run `task dev` (never exits) or a bare `task` (interactive menu).
- Never run `php`, `composer`, `bun` or `node` directly: they don't exist on the host, and in the sandbox `task` is the only supported entry point.

## Layout

- Standard Laravel layout. Business logic goes in `app/` classes (actions or services), not in controllers, routes or models.
- Frontend: Vite with Bun (`bun`, never `npm`/`pnpm`/`yarn`; the lockfile is `bun.lock`).
- Tests are Pest, in `tests/`. They run on the separate `testing` database; never point them at the dev database.
- Architecture decisions live in `docs/decisions/`; read the relevant one before changing that area, and add one for each new decision.

## Rules

- For new behavior, write a failing test first, then the implementation.
- Pest has arch tests (`tests/Unit/ArchTest.php`), and both type coverage and code coverage must be 100% (`test:types` and `test:coverage` in `composer.json`); never lower them, and never add `@codeCoverageIgnore` or `@pest-ignore-type` to new code: write the test or the type. Larastan runs at `level: max` in `phpstan.neon`, with Pest's PHPStan plugin installed. Fix the code; don't add `@phpstan-ignore` or grow the baseline without asking.
- `declare(strict_types=1);` in every PHP file that you create. Type every parameter, return value and property.
- Ask before adding a dependency. Add with `task composer -- require <pkg>` or `task bun -- add <pkg>`.
- Never run `config:cache` locally: it writes every secret in plain text to `bootstrap/cache/config.php`.
- Never read or write `.env`; use `.env.example` for documentation of variables.
- Keep changes focused; don't refactor unrelated code.
