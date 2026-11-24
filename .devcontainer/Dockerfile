# syntax=docker/dockerfile:1

# Dev image for the app and (as base) for the agent sandbox.
# The PHP minor is the one thing that is pinned (see docs/decisions/004-stack-choices.md): the newest
# PHP minor is often not supported by extensions and packages for months, so a floating tag breaks.
# Dependabot proposes the bump (it can't see through an ARG, hence the literal tag); CI shows whether
# it works. Everything else (Composer, Bun, the installer) is unpinned and follows the latest
# release on `task build:dev`.
FROM php:8.6-cli-trixie

# git/unzip: Composer; rsync: `task init`; postgresql-client: `artisan db` and dumps
RUN apt-get update && apt-get install -y --no-install-recommends git unzip rsync postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Extensions for Laravel on Postgres (redis is used when you opt in to Redis)
COPY --from=ghcr.io/mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/
RUN install-php-extensions pdo_pgsql intl zip bcmath pcntl redis opcache

# Pest's type coverage runs PHPStan inside the PHP process, and the CLI default of 128M is too little
RUN echo "memory_limit=1G" > "$PHP_INI_DIR/conf.d/zz-memory.ini"

COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer
# Bun replaces Node and pnpm: it runs Vite and installs the frontend packages
COPY --from=oven/bun:latest /usr/local/bin/bun /usr/local/bin/bun
RUN ln -s /usr/local/bin/bun /usr/local/bin/bunx

ENV COMPOSER_HOME=/composer \
    COMPOSER_ALLOW_SUPERUSER=1 \
    PATH=/composer/vendor/bin:$PATH
# api.github.com answers 504 on unauthenticated zipball downloads often enough to break installs;
# without the API Composer downloads the archives from github.com, which is not rate limited.
# Always the newest installer (the Laravel starter kits come with it).
RUN composer config --global use-github-api false \
    && composer global require laravel/installer --no-interaction && composer clear-cache

WORKDIR /app
