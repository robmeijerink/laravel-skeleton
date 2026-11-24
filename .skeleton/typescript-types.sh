#!/usr/bin/env bash
# laravel-data with generated TypeScript types, for the stacks with a TypeScript frontend (React, Vue and
# the SPA stubs). PHP classes marked #[TypeScript] (Data objects, enums) become types in
# resources/js/generated/generated.d.ts. `composer qa` regenerates the file and lets the frontend
# formatter (Oxfmt) format it; CI regenerates it and fails when it differs from the committed file.
set -euo pipefail
source .skeleton/lib.sh

composer require spatie/laravel-data spatie/laravel-typescript-transformer --no-interaction --quiet
# Registers the service provider in bootstrap/providers.php; the provider itself is replaced below
php artisan typescript:install --no-interaction > /dev/null

# The installer's provider formats with Prettier, which needs Node; Oxfmt does that in `composer qa`
cat > app/Providers/TypeScriptTransformerServiceProvider.php <<'PHP'
<?php

declare(strict_types=1);

namespace App\Providers;

use Spatie\LaravelTypeScriptTransformer\LaravelData\LaravelDataTypeScriptTransformerExtension;
use Spatie\LaravelTypeScriptTransformer\TypeScriptTransformerApplicationServiceProvider;
use Spatie\TypeScriptTransformer\Transformers\AttributedClassTransformer;
use Spatie\TypeScriptTransformer\Transformers\EnumTransformer;
use Spatie\TypeScriptTransformer\TypeScriptTransformerConfigFactory;
use Spatie\TypeScriptTransformer\Writers\GlobalNamespaceWriter;

// Generates TypeScript types for every class in app/ marked #[TypeScript], including laravel-data
// objects, into resources/js/generated/generated.d.ts (`composer types:generate`).
final class TypeScriptTransformerServiceProvider extends TypeScriptTransformerApplicationServiceProvider
{
    protected function configure(TypeScriptTransformerConfigFactory $config): void
    {
        $config
            ->extension(new LaravelDataTypeScriptTransformerExtension())
            ->transformer(AttributedClassTransformer::class)
            ->transformer(EnumTransformer::class)
            ->transformDirectories(app_path())
            ->writer(new GlobalNamespaceWriter('generated.d.ts'));
    }
}
PHP

mkdir -p resources/js/generated
php artisan typescript:transform --quiet
