#!/bin/bash

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purpose

# Load Moodle environment
. /opt/bitnami/scripts/moodle-env.sh

# Load web server environment and functions (after Moodle environment file so MODULE is not set to a wrong value)
. /opt/bitnami/scripts/libwebserver.sh

# Load libraries
. /opt/bitnami/scripts/liblog.sh
. /opt/bitnami/scripts/libservice.sh

# Catch SIGTERM signal and stop all child processes
_forwardTerm () {
    warn "Caught signal SIGTERM, passing it to child processes..."
    pgrep -P $$ | xargs kill -TERM 2>/dev/null
    wait
    exit $?
}
trap _forwardTerm TERM

# Start cron
if am_i_root; then
    info "** Starting cron **"
    if ! cron_start; then
        error "Failed to start cron. Check that it is installed and its configuration is correct."
        exit 1
    fi
else
    warn "Cron will not be started because of running as a non-root user"
fi

# Start Apache
if [[ -f "/opt/bitnami/scripts/nginx-php-fpm/run.sh" ]]; then
    exec "/opt/bitnami/scripts/nginx-php-fpm/run.sh"
else
    exec "/opt/bitnami/scripts/$(web_server_type)/run.sh"
fi
