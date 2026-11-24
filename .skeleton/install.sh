#!/usr/bin/env bash
# Container side of `task init`: lets the official Laravel installer create the app in a temporary
# folder (it refuses a non-empty one), merges it into the repo without overwriting skeleton files,
# applies the skeleton's settings, then removes everything that was only needed for init.
set -euo pipefail
cd /app
source .skeleton/lib.sh

STACK="$1" AUTH="$2" FILAMENT="$3" MAILPIT="$4" REDIS="$5" NAME="$6"
TMP=/tmp/laravel-app
rm -rf "$TMP"

# ---- 1. Laravel installer, always the newest release and starter kits -------------------------
composer global update laravel/installer --no-interaction --quiet
args=(--database=pgsql --pest --bun --no-boost --no-interaction)
[ "$AUTH" = 1 ] || args+=(--no-authentication)
case "$STACK" in
  react|vue|livewire) args+=("--$STACK") ;;
  blade|spa-react|spa-vue) ;; # no starter kit
  *) echo "Unknown stack: $STACK" >&2; exit 1 ;;
esac
# The kits run a post-install hook (`install:features`) that calls npm when told nothing else; this image
# has no Node. With this flag the hook skips it and the installer installs the packages with Bun itself.
(cd /tmp && LARAVEL_INSTALLER_NO_NODE=1 laravel new laravel-app "${args[@]}")

# ---- 2. Merge into the repo: skeleton files win, the app's own files are added ----------------
# vendor/ and node_modules/ are reinstalled below: their paths and caches point at /tmp
rsync -a --ignore-existing \
  --exclude=/.git --exclude=/vendor --exclude=/node_modules --exclude=/.github \
  --exclude=/README.md --exclude='/bootstrap/cache/*.php' --exclude=/AGENTS.md --exclude=/CLAUDE.md \
  "$TMP"/ /app/
# .gitignore: keep ours, add the lines Laravel has that we don't
grep -vxFf .gitignore "$TMP/.gitignore" >> .gitignore || true
rm -rf "$TMP"

# ---- 3. Own stubs for the stacks without a starter kit ----------------------------------------
if [ -d ".skeleton/stubs/$STACK" ]; then
  composer install --no-interaction --no-progress --quiet
  bash ".skeleton/stubs/$STACK/install.sh"
fi

# ---- 4. Database, Postgres in Compose; tests on their own database ----------------------------
for f in .env .env.example; do
  setenv "$f" APP_NAME "$NAME"
  setenv "$f" APP_URL http://localhost:8000
  setenv "$f" DB_CONNECTION pgsql
  setenv "$f" DB_HOST postgres
  setenv "$f" DB_PORT 5432
  setenv "$f" DB_DATABASE app
  setenv "$f" DB_USERNAME app
  setenv "$f" DB_PASSWORD secret
done

# ---- 5. Dependencies in the repo (node_modules was left behind in the temporary folder) ------
composer install --no-interaction --no-progress --quiet
[ -f package.json ] && bun install --no-progress
# Oxlint and Oxfmt where the starter kit doesn't bring its own frontend checks
bash .skeleton/frontend-tools.sh
# Add-ons
[ "$MAILPIT" = 1 ] && bash .skeleton/addons/mailpit.sh
[ "$REDIS" = 1 ] && bash .skeleton/addons/redis.sh
[ "$FILAMENT" = 1 ] && bash .skeleton/addons/filament.sh
for block in mailpit redis; do
  var=$(echo "$block" | tr a-z A-Z)
  if [ "${!var}" = 1 ]; then keep_block .devcontainer/docker-compose.yml "$block"; else drop_block .devcontainer/docker-compose.yml "$block"; fi
done

# ---- 6. Tests: committed .env.testing with fake values, never the dev data --------------------
cp .env.example .env.testing
setenv .env.testing APP_ENV testing
setenv .env.testing APP_KEY "base64:$(printf 'fake-key-only-for-the-tests-1234' | base64)"
setenv .env.testing APP_DEBUG true
setenv .env.testing DB_DATABASE testing
setenv .env.testing CACHE_STORE array
setenv .env.testing SESSION_DRIVER array
setenv .env.testing QUEUE_CONNECTION sync
setenv .env.testing MAIL_MAILER array
setenv .env.testing BCRYPT_ROUNDS 4
# phpunit.xml may not override the database with SQLite from the installer's template
sed -i '/name="DB_CONNECTION"/d;/name="DB_DATABASE"/d;/name="DB_URL"/d' phpunit.xml
sed -i 's|^\( *\)<env name="APP_ENV" value="testing"/>|&\n\1<env name="DB_CONNECTION" value="pgsql"/>\n\1<env name="DB_DATABASE" value="testing"/>|' phpunit.xml
grep -q 'name="DB_DATABASE" value="testing"' phpunit.xml || { echo "phpunit.xml: could not set the testing database" >&2; exit 1; }
# Inertia kits: while `task dev` runs (public/hot exists), Inertia renders server-side through the Vite
# dev server. In tests that is a real HTTP request, which Essentials blocks, so every page would fail
# with a 500. Tests render client-side only; the setting stays on everywhere else.
if [ -f config/inertia.php ]; then
  sed -i "s/^\(\s*\)'enabled' => true,/\1'enabled' => (bool) env('INERTIA_SSR_ENABLED', true),/" config/inertia.php
  grep -q "INERTIA_SSR_ENABLED" config/inertia.php || { echo "config/inertia.php: could not make SSR configurable for the tests" >&2; exit 1; }
  sed -i 's|^\( *\)<env name="APP_ENV" value="testing"/>|&\n\1<env name="INERTIA_SSR_ENABLED" value="false"/>|' phpunit.xml
fi

# ---- 7. Quality tooling: Larastan (max), Pest plugins, Rector, Essentials ---------------------
composer require --dev --no-interaction --quiet \
  larastan/larastan pestphp/pest-plugin-arch pestphp/pest-plugin-type-coverage pestphp/pest-plugin-phpstan \
  rector/rector
# Stricter Laravel defaults (strict models, immutable dates, no destructive commands in production, ...)
composer require nunomaduro/essentials --no-interaction --quiet
cat > rector.php <<'RECTOR'
<?php

declare(strict_types=1);

use Rector\Config\RectorConfig;

// Kept to the stable, documented core of Rector so it keeps working across major versions
return RectorConfig::configure()
    ->withPaths([__DIR__.'/app', __DIR__.'/config', __DIR__.'/database', __DIR__.'/routes', __DIR__.'/tests'])
    ->withPhpSets()
    ->withPreparedSets(deadCode: true, codeQuality: true, typeDeclarations: true);
RECTOR
# The kits bring their own phpstan.neon (level 7); the skeleton raises it to max. Without a kit, write one.
if [ -f phpstan.neon ]; then
  sed -i 's/^\( *level:\) .*/\1 max/' phpstan.neon
else
  cat > phpstan.neon <<'NEON'
includes:
    - vendor/larastan/larastan/extension.neon

parameters:
    level: max
    paths:
        - app
        - config
        - database
        - routes
NEON
fi
grep -q 'level: max' phpstan.neon || { echo "phpstan.neon: could not set level max" >&2; exit 1; }
rm -f pnpm-workspace.yaml
mkdir -p tests/Unit
cat > tests/Unit/ArchTest.php <<'PHP'
<?php

declare(strict_types=1);

// Architecture rules: they fail the build when code breaks the house style. Add your own per project,
// e.g. arch()->expect('App\Models')->toExtend('Illuminate\Database\Eloquent\Model').
arch()->preset()->php();
arch()->preset()->security();
PHP
# One definition of "is it good", used by `task check`, the sandbox and CI
php -r '
  $file = "composer.json";
  $json = json_decode(file_get_contents($file), true, 512, JSON_THROW_ON_ERROR);
  $json["scripts"]["fix"] = "pint --quiet";
  $json["scripts"]["stan"] = "phpstan analyse --no-progress --memory-limit=1G";
  $json["scripts"]["test:unit"] = "pest --compact";
  $json["scripts"]["test:types"] = "pest --type-coverage --min=100 --compact";
  $json["scripts"]["rector"] = "rector --no-progress-bar";
  // The tests run once, with coverage (pcov), and fail below the minimum
  $json["scripts"]["test:coverage"] = "pest --coverage --min=100 --compact";
  // Frontend: reuse the scripts the starter kit (or SPA stub) defines; Blade and Livewire have none
  $npm = is_file("package.json") ? (json_decode(file_get_contents("package.json"), true)["scripts"] ?? []) : [];
  $front = $frontCi = [];
  if (isset($npm["check:fix"], $npm["check"])) { $front[] = "bun run check:fix"; $frontCi[] = "bun run check"; }
  if (isset($npm["types:check"])) { $front[] = $frontCi[] = "bun run types:check"; }
  // Composer kills a script after 300s; a cold PHPStan cache on a slow machine can need longer
  $json["scripts"]["qa"] = ["Composer\\Config::disableProcessTimeout", "@rector", "@fix", ...$front, "@stan", "@test:coverage", "@test:types"];
  $json["scripts"]["qa:ci"] = ["Composer\\Config::disableProcessTimeout", "rector --dry-run --no-progress-bar", "pint --test", ...$frontCi, "@stan", "@test:coverage", "@test:types"];
  file_put_contents($file, json_encode($json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE) . "\n");
'

# ---- 8. Bun instead of npm in the scripts the installer wrote ---------------------------------
sed -i 's/npm run /bun run /g; s/npm install/bun install/g; s/npx /bunx /g' composer.json
bash .skeleton/patch-vite.sh

# ---- 9. Secrets out of the agent's reach: .env lives in .secrets/ and is symlinked ------------
mkdir -p .secrets
mv .env .secrets/.env
ln -s .secrets/.env .env

# ---- 10. Format, baseline for code the installer wrote, clean up ------------------------------
# Bring the installer's own code up to the house rules: Rector adds missing types, Pint formats
vendor/bin/rector --no-progress-bar > /dev/null 2>&1 || true
vendor/bin/pint --quiet || true
[ -f package.json ] && { bun run check:fix > /dev/null 2>&1 || true; }
vendor/bin/phpstan analyse --no-progress --memory-limit=1G --generate-baseline > /dev/null 2>&1 || true
if [ -s phpstan-baseline.neon ] && grep -q 'message' phpstan-baseline.neon; then
  sed -i 's|^includes:|&\n    - phpstan-baseline.neon|' phpstan.neon
else
  rm -f phpstan-baseline.neon
fi
# Type coverage must be 100. Whatever the installer's code still lacks after Rector gets a line-level
# `@pest-ignore-type` marker (listed below), so the minimum stays 100 for everything written afterwards.
# If that does not get to 100 either, start at the measured value and say so instead of shipping a red
# first `task check`; the minimum only goes up.
coverage() {
  vendor/bin/pest --type-coverage --min=0 2>&1 | sed 's/\x1b\[[0-9;]*m//g'
}
total() { grep -o 'Total: *[0-9.]*' | grep -o '[0-9.]*$' | head -1 || true; }
report=$(coverage)
if [ "$(echo "$report" | total | cut -d. -f1)" -lt 100 ]; then
  echo "NOTE: untyped code from the installer that Rector could not fix, marked with @pest-ignore-type:" >&2
  echo "$report" | php .skeleton/ignore-untyped.php > /dev/null
  vendor/bin/pint --quiet || true
  report=$(coverage)
fi
total=$(echo "$report" | total)
if [ -n "$total" ] && [ "${total%.*}" -lt 100 ]; then
  sed -i "s/--type-coverage --min=100/--type-coverage --min=${total%.*}/" composer.json
  echo "NOTE: type coverage is still ${total}% after marking; the minimum starts at ${total%.*} instead of 100." >&2
fi

# Code coverage must be 100 as well, the same way: statements of the installer's code that its own
# tests don't reach get a line-level `@codeCoverageIgnore` marker (PHPUnit's mechanism), so every line
# written afterwards needs a test. Needs the database, which is why init starts Postgres.
code_coverage() { vendor/bin/pest --coverage --min=0 --compact 2>&1 | sed 's/\x1b\[[0-9;]*m//g'; }
ctotal=$(code_coverage | total)
if [ -n "$ctotal" ] && [ "${ctotal%.*}" -lt 100 ]; then
  echo "NOTE: untested code from the installer, marked with @codeCoverageIgnore:" >&2
  vendor/bin/pest --coverage-clover /tmp/clover.xml > /dev/null 2>&1 || true
  php .skeleton/ignore-uncovered.php /tmp/clover.xml || true
  vendor/bin/pint --quiet || true
  ctotal=$(code_coverage | total)
fi
if [ -z "$ctotal" ]; then
  echo "NOTE: could not measure code coverage (do the tests pass?); the minimum stays 100." >&2
elif [ "${ctotal%.*}" -lt 100 ]; then
  sed -i "s/pest --coverage --min=100/pest --coverage --min=${ctotal%.*}/" composer.json
  echo "NOTE: code coverage is still ${ctotal}% after marking; the minimum starts at ${ctotal%.*} instead of 100." >&2
fi

sed -i 's/laravel-skeleton/'"$NAME"'/g' .devcontainer/devcontainer.json
drop_block Taskfile.yaml skeleton
# The project's CI lives in the template as .skeleton/ci.yml: in the template itself it would fail (no app yet)
mkdir -p .github/workflows && mv .skeleton/ci.yml .github/workflows/ci.yml
cp .skeleton/README.project.md README.md
sed -i "s/__NAME__/$NAME/g" README.md
# The template's MIT LICENSE is not the project's: pick your own (the Laravel app itself is MIT in composer.json)
rm -rf .skeleton .github/workflows/skeleton-smoke.yml LICENSE
echo "Done. Next: task check, then task dev"
