#!/usr/bin/env bash
set -euo pipefail
source .skeleton/lib.sh
setenv_all MAIL_MAILER smtp
setenv_all MAIL_HOST mailpit
setenv_all MAIL_PORT 1025
