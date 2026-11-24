# 004: Stack Choices and How They Stay Current

* **PostgreSQL**, in dev, tests, CI and production. No SQLite: it behaves differently from Postgres (types, constraints, locking), so tests would pass on something production is not.
* **Bun** replaces Node and pnpm in the dev image, the sandbox and the production build: package manager and runtime for Vite. There is no Node in the image, so a tool that insists on Node fails visibly; Bun then supplies the `node` shim for scripts. The installer runs with `--bun`; `init` rewrites the `npm run` calls in `composer.json` scripts (`composer run dev`) to `bun run`.
* **Pest**, with the arch, type-coverage and PHPStan plugins; **Larastan** at `level: max`; **Pint** with Laravel's default preset; **Rector** (stable core sets only); **Essentials** for stricter Laravel defaults. Inspired by `scajal/laravel-react-starter-kit`.
* **Production on FrankenPHP in classic mode**, not Octane's worker mode: workers keep the application in memory between requests, which makes static state, singletons and leaks a source of bugs. Worker mode can be adopted per project later; it is a deliberate step, not the default.
* **Dev image on `php:<minor>-cli-trixie`**, production on `dunglas/frankenphp:1-php<minor>-trixie`.

## Staying Current
Everything floats to the latest release (installer, starter kits, Composer, Bun, Postgres, Mailpit, Redis) **except the PHP minor**, which is written literally in both Dockerfiles. Reason: on 2026-11-23 `php:cli-trixie` was PHP 8.6.0, a day-old minor for which `phpredis` did not compile yet. A floating tag would have broken the build the moment a new PHP appears, while a pinned minor only moves when CI says it works.

* **Dependabot** (weekly) proposes the PHP bump (`FROM` lines cannot be updated through an `ARG`, hence the literal tags), Composer, Bun and Actions updates.
* **The production PHP version is changed by hand.** Dependabot does not recognise the FrankenPHP tag `1-php8.5-trixie` as a PHP version (found 2026-11-24: its PHP 8.6 PR covered only `.devcontainer/Dockerfile`). Without a guard, a green PHP bump would auto-merge and leave dev and production on different PHP versions. A step in CI and in the smoke test (*PHP versions match*) fails while the two differ and names the line to change. The tag `php8.5-trixie` might be recognised, but it floats over FrankenPHP majors; a one-line edit about once a year was preferred.
* **Auto-merge** (`dependabot-automerge.yml`) merges minor and patch PRs once the required checks are green. This needs the repo setting "Allow auto-merge" and a branch protection rule or ruleset on `main` that requires the checks; without one `--auto` merges immediately. The workflow therefore refuses to enable auto-merge on an unprotected branch. Major versions stay open for a human.
* **What is required where:** in a generated project the two jobs of `ci.yml` (**Format, Analyse & Test**, **Build Docker Image**); in the template repo the six *Skeleton smoke test* jobs. The template has no `ci.yml` (kept as `.skeleton/ci.yml`, moved into place by `init`), because without an app it can only fail.
* **Lesson (2026-11-24):** the first Dependabot PR bumped PHP to 8.6 and was merged by auto-merge although every check was red (`phpredis` does not build on 8.6): branch protection was not yet active. The smoke test caught it; the missing gate let it through. Hence the guard above.
* **A red Dependabot PR is the only thing that needs attention.** That is the intended amount of maintenance.

## Production Image
The image (see `Dockerfile` and the README) takes all configuration from the environment at runtime, has a healthcheck on `/up`, and leaves out what a single web process should not do: the queue worker and scheduler (run the same image with another command) and Inertia SSR (no Bun or Node in the image; adding SSR means a Node/Bun runtime in the image and a second process, a per-project decision). `init` removes the template's `LICENSE` from generated projects.

## Development Environment Details
* **`memory_limit=1G` in the dev image:** Pest's type coverage runs PHPStan inside the PHP process and the CLI default (128M) is exhausted.
* **Vite polls for file changes** (`CHOKIDAR_USEPOLLING`, every 300 ms). Verified on macOS with Colima: a change made inside the container produced an HMR update, the same change made from the host produced none, so hot reload never fired for edits in your editor. The environment variable avoids patching each kit's Vite config.
* **pcov in the dev image only**, for code coverage; production has no coverage driver.
* **No Postgres port on the host:** a fixed `5432` clashes with every other project. The containers use `postgres:5432`. The app (8000), Vite (5173) and Mailpit (8025) are published on `127.0.0.1` only; change them per project if they clash.
* **`composer qa`** (Rector, Pint, Larastan, Pest, type coverage) is the single definition of "checked"; `qa:ci` is the same as dry runs for Rector and Pint. Both disable Composer's 300s process timeout.
