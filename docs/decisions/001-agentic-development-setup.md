# 001: Agentic Development Setup

This skeleton is set up so an agent works efficiently (few tokens) and the codebase stays manageable as it grows. This rationale lives in a decision record rather than in `AGENTS.md`, because everything in `AGENTS.md` is loaded into every agent session, and rather than in the README, because a project's README gets rewritten.

## 1. A Lean `AGENTS.md`
`AGENTS.md` is the cross-tool standard for agent instructions; `CLAUDE.md` only imports it. It contains just what an agent cannot derive from the code: which commands to use, the layout and the house rules. Every line costs tokens in every session, so keep it short and never explain Laravel itself.

## 2. One Quiet Feedback Loop
`task check` is the single "am I done?" command. It runs `composer qa`: Rector and Pint (they fix instead of only checking, so an agent never spends a round trip on formatting or trivial refactors; CI runs both as dry runs and rejects the diff), Larastan at max level, Pest, and Pest's type coverage. The steps are Composer scripts in `composer.json`, so Taskfile, the sandbox's `task` shim and CI run the same definition and cannot drift apart. Output is quiet: a passing run costs a handful of lines while static-analysis errors stay complete. [laravel/pao](https://github.com/laravel/pao) goes further when an agent runs the tools: Pest, Paratest, PHPStan, Rector and Artisan print compact JSON instead of human output. It detects the agent through environment variables (`CLAUDECODE`, `AI_AGENT`, `CURSOR_AGENT`), which the `app` service passes through from the host; in the sandbox Claude Code sets them itself.

## 3. Guardrails as Tools, Not Prose
* **Larastan at `level: max`** (plus Pest's PHPStan plugin) catches loose types and deprecated calls on every run, at zero token cost.
* **Pest arch tests** (`tests/Unit/ArchTest.php`) fail the build when code breaks a structural rule.
* **Type coverage with a minimum of 100** makes untyped code fail the build. The minimum only goes up. Rector's type-declaration sets add missing types to the installer's own code during `init`; what it cannot type gets a line-level `// @pest-ignore-type` marker, so the minimum stays 100 for new code (see [003](003-template-and-init.md)).
* **Rector** (`rector.php`, kept to the stable core: dead code, code quality, type declarations, PHP sets) keeps code modern without a human sweep.
* **Frontend checks** for every stack: the React and Vue kits bring Oxlint and Oxfmt through Vite+ (`check`, `check:fix`) and a `types:check`; for Blade, Livewire and the SPA stubs `init` adds Oxlint and Oxfmt directly (`.skeleton/frontend-tools.sh`, same style as the kits, scoped to `resources/js`), and the SPA stubs get a `types:check`. `init` adds whatever exists to `composer qa`. Without them a TypeScript error would pass `task check` and CI, because `bun run build` does not typecheck.
* **Code coverage with a minimum of 100**, measured with pcov in the dev image; the tests run once per `task check`, with coverage. The installer's own untested statements are marked once with `// @codeCoverageIgnore` (see [003](003-template-and-init.md)), so every line written afterwards needs a test. A measured starting value (96% for the React kit) was rejected: it would let new untested code through as long as the total did not drop.
* **Essentials** (`nunomaduro/essentials`) turns on stricter Laravel defaults: strict models, immutable dates, destructive commands blocked in production.
* **Code the installer wrote** that violates max level is recorded once in `phpstan-baseline.neon`; new code gets no such allowance.

## 4. Manageability
* **Shared permissions:** `.claude/settings.json` pre-approves `task` and read-only git commands, asks before adding dependencies, and blocks direct `php`, `composer`, `bun` and `node` (the host has none, and `task` is the one supported entry point) and `task dev` (never exits). Personal overrides go in `.claude/settings.local.json` (git-ignored).
* **Tests as specification:** have the agent write a failing test first. You review the test, which is shorter than the implementation.
* **Small tasks, short sessions:** one feature per session, commit, then `/clear`.
* **Decision records:** record each architecture decision as a short, numbered file in `docs/decisions/`, like this one.
