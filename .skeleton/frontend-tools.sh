#!/usr/bin/env bash
# Oxlint and Oxfmt for the stacks whose starter kit doesn't bring them (Blade, Livewire, the SPA stubs).
# The React and Vue kits run the same tools through Vite+ (`vp check`); this gives the other stacks the
# same checks and the same style (single quotes, 4 spaces), as the `check` and `check:fix` scripts that
# `composer qa` picks up. Scoped to resources/js: the tools would otherwise read node_modules and
# reformat composer.json and the template's own files.
set -euo pipefail

[ -f package.json ] || exit 0
# A kit with its own check script keeps it
php -r 'exit(isset(json_decode(file_get_contents("package.json"), true)["scripts"]["check"]) ? 0 : 1);' && exit 0

bun add -d oxlint oxfmt
cat > .oxfmtrc.json <<'JSON'
{
    "$schema": "./node_modules/oxfmt/configuration_schema.json",
    "singleQuote": true,
    "tabWidth": 4
}
JSON
# Laravel's own resources/js/app.js is empty on purpose (an entry point for Vite); Oxlint's
# no-empty-file rule would fail on it. Every other default rule stays on.
cat > .oxlintrc.json <<'JSON'
{
    "$schema": "./node_modules/oxlint/configuration_schema.json",
    "rules": {
        "unicorn/no-empty-file": "off"
    }
}
JSON
php -r '
  $file = "package.json";
  $json = json_decode(file_get_contents($file), true, 512, JSON_THROW_ON_ERROR);
  $json["scripts"]["check"] = "oxlint --deny-warnings resources/js && oxfmt --check resources/js";
  $json["scripts"]["check:fix"] = "oxlint --deny-warnings --fix resources/js && oxfmt resources/js";
  file_put_contents($file, json_encode($json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\n");
'
