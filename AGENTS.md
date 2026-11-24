# AGENTS.md

Laravel project on PostgreSQL. All tooling runs in Docker via Task; PHP, Pun, Composer and Bun on the host are not used.

## Commands

- `task check`: Pun (`pun check --fix`: formats, applies lint fixes, analyses at PHPStan level max) and the frontend formatter (they edit files), the TypeScript check, Pest and type coverage (`composer qa`). Run it after every change; work is done only when it passes.
- `task test -- --filter=Name`: Pest, for the red/green loop on one test. Add `--coverage` for a coverage report.
- `task artisan -- <args>`, `task pun -- <args>`, `task composer -- <args>`, `task bun -- <args>`: any other command, e.g. `task artisan -- make:model Post -m`. PHP packages go through Pun (`task pun -- require <pkg>`); Composer only runs scripts.
- Don't run `task dev` (never exits) or a bare `task` (interactive menu).
- Never run `php`, `pun`, `composer`, `bun` or `node` directly: they don't exist on the host, and in the sandbox `task` is the only supported entry point.

## Layout

- Standard Laravel layout. Business logic goes in `app/` classes (actions or services), not in controllers, routes or models.
- Frontend: Vite with Bun (`bun`, never `npm`/`pnpm`/`yarn`; the lockfile is `bun.lock`).
- Data objects: use laravel-data where the stack has TypeScript; mark them (and enums the frontend needs) `#[TypeScript]`, run `task check`, and use the generated type from `resources/js/generated/generated.d.ts` instead of writing it by hand.
- Tests are Pest, in `tests/`. They run on the separate `testing` database; never point them at the dev database.
- Architecture decisions live in `docs/decisions/`; read the relevant one before changing that area, and add one for each new decision.

## Rules

- For new behavior, write a failing test first, then the implementation.
- Pest has arch tests (`tests/Unit/ArchTest.php`), and both type coverage and code coverage must be 100% (`test:types` and `test:coverage` in `composer.json`); never lower them, and never add `@codeCoverageIgnore` or `@pest-ignore-type` to new code: write the test or the type. Pun analyses at PHPStan level max (`pun.toml`). Fix the code; don't add `@pun-ignore` or grow `pun-baseline.toml` without asking.
- `declare(strict_types=1);` in every PHP file that you create. Type every parameter, return value and property.
- Ask before adding a dependency. Add with `task pun -- require <pkg>` or `task bun -- add <pkg>`.
- Never run `config:cache` locally: it writes every secret in plain text to `bootstrap/cache/config.php`.
- Never read or write `.env`; use `.env.example` for documentation of variables.
- Keep changes focused; don't refactor unrelated code.
