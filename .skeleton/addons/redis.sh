#!/usr/bin/env bash
set -euo pipefail
source .skeleton/lib.sh
setenv_all REDIS_CLIENT phpredis
setenv_all REDIS_HOST redis
setenv_all CACHE_STORE redis
setenv_all SESSION_DRIVER redis
setenv_all QUEUE_CONNECTION redis
