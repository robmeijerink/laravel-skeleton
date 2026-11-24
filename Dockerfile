# syntax=docker/dockerfile:1

# Production image: FrankenPHP (Caddy + PHP in one process), classic mode (no Octane worker, so no
# state leaks between requests). The PHP minor must match .devcontainer/Dockerfile; Dependabot bumps both.
FROM dunglas/frankenphp:1-php8.5-trixie AS base
RUN install-php-extensions pdo_pgsql intl zip bcmath pcntl redis opcache
WORKDIR /app

# Build stage: Pun and Bun live only here. The frontend build can call artisan (e.g. route
# generators in the Vite plugins), so it runs after `pun install`.
FROM base AS build
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates && rm -rf /var/lib/apt/lists/*
# Pun installs the packages; the installer verifies the SHA-256 checksum (docs/decisions/005-pun.md)
RUN curl -fsSL https://punphp.com/install | PUN_INSTALL=/usr/local sh
COPY --from=oven/bun:latest /usr/local/bin/bun /usr/local/bin/bun
COPY composer.json composer.lock ./
# Copies, not hardlinks: the package store is in a cache mount, another filesystem
ENV PUN_CACHE_DIR=/root/.cache/pun PUN_LINK_MODE=copy
RUN --mount=type=cache,target=/root/.cache/pun \
    pun install --no-dev --no-scripts --no-autoloader
COPY package.json bun.lock* ./
RUN --mount=type=cache,target=/root/.bun/install/cache \
    if [ -f package.json ]; then bun install --frozen-lockfile; fi
COPY . .
# A throwaway key and env: the build must not need real secrets, and none end up in the image
ENV APP_ENV=production APP_KEY=base64:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
RUN pun composer dump-autoload --optimize --no-dev --classmap-authoritative \
    && if [ -f package.json ]; then bun run build; fi \
    && rm -rf node_modules \
    # The runtime user (www-data) must read every file. A checkout can hold files only its owner can
    # read: on macOS bind mounts, `sed -i` in the container (as `task init` does) leaves them at 0600
    && chmod -R a+rX .

# Runtime stage: no Pun, no Bun, non-root.
FROM base AS runtime
RUN cp "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
COPY --from=build /app /app
# Listen on an unprivileged port so the process can run as www-data (Caddy needs write access to /data and /config)
ENV SERVER_NAME=:8080
RUN mkdir -p storage/framework/cache storage/framework/sessions storage/framework/views storage/logs bootstrap/cache \
    && chown -R www-data:www-data storage bootstrap/cache /data/caddy /config/caddy
USER www-data
EXPOSE 8080
# Laravel's built-in health route; the image has no curl, so PHP does the request
HEALTHCHECK --interval=30s --timeout=3s --start-period=15s --retries=3 \
    CMD php -r 'exit(@file_get_contents("http://127.0.0.1:8080/up") === false ? 1 : 0);'
