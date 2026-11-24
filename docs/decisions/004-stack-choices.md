# 004: Stack Choices and How They Stay Current

* **PostgreSQL**, in dev, tests, CI and production. No SQLite: it behaves differently from Postgres (types, constraints, locking), so tests would pass on something production is not.
* **Bun** replaces Node and pnpm in the dev image, the sandbox and the production build: package manager and runtime for Vite. There is no Node in the image, so a tool that insists on Node fails visibly; Bun then supplies the `node` shim for scripts. The installer runs with `--bun`; `init` rewrites the `npm run` calls in `composer.json` scripts (`composer run dev`) to `bun run`.
* **Pest**, with the arch, type-coverage and PHPStan plugins; **Larastan** at `level: max`; **Pint** with Laravel's default preset; **Rector** (stable core sets only); **Essentials** for stricter Laravel defaults. Inspired by `scajal/laravel-react-starter-kit`.
* **Production on FrankenPHP in classic mode**, not Octane's worker mode: workers keep the application in memory between requests, which makes static state, singletons and leaks a source of bugs. Worker mode can be adopted per project later; it is a deliberate step, not the default.
* **Dev image on `php:<minor>-cli-trixie`**, production on `dunglas/frankenphp:1-php<minor>-trixie`.

## Staying Current
Everything floats to the latest release (installer, starter kits, Composer, Bun, Postgres, Mailpit, Redis) **except the PHP minor**, which is written literally in both Dockerfiles. Reason: on 2026-11-23 `php:cli-trixie` was PHP 8.6.0, a day-old minor for which `phpredis` did not compile yet. A floating tag would have broken the build the moment a new PHP appears, while a pinned minor only moves when CI says it works.

* **Dependabot** (weekly) proposes the PHP bump (`FROM` lines cannot be updated through an `ARG`, hence the literal tags), Composer, Bun and Actions updates.
* **Auto-merge** (`dependabot-automerge.yml`) merges minor and patch PRs once CI is green. This needs the repo setting "Allow auto-merge" and a branch protection rule on `main` that requires the CI checks; without it `--auto` merges immediately. Major versions stay open for a human.
* **A red Dependabot PR is the only thing that needs attention.** That is the intended amount of maintenance.

## Development Environment Details
* **`memory_limit=1G` in the dev image:** Pest's type coverage runs PHPStan inside the PHP process and the CLI default (128M) is exhausted.
* **No Postgres port on the host:** a fixed `5432` clashes with every other project. The containers use `postgres:5432`. The app (8000), Vite (5173) and Mailpit (8025) are published on `127.0.0.1` only; change them per project if they clash.
* **`composer qa`** (Pint, Larastan, Pest, type coverage) is the single definition of "checked"; `qa:ci` is the same with `pint --test`. Both disable Composer's 300s process timeout.
