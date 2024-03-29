#!/bin/bash

# docs: https://go-acme.github.io/lego/usage/cli/
# Path: /usr/local/bin/entrypoint.sh

set -e

# Check if incoming command contains flags
if [ "${1#-}" != "$1" ]; then
    set -- lego "$@"
elif [[ -n "$ENV_LEGO_ENABLE" ]] && [[ "$ENV_LEGO_ENABLE" = "true" ]]; then
    args=""
    op=""

    # Operation types
    if [[ -n "$ENV_LEGO_RENEW" ]] && [[ "$ENV_LEGO_RENEW" = "true" ]]; then
        op=" renew"
        if [[ -n "$ENV_LEGO_RENEW_DAYS" ]]; then
            op="$op --days=$ENV_LEGO_RENEW_DAYS"
        fi

        if [[ -n "$ENV_LEGO_RENEW_HOOK" ]]; then op="$op --renew-hook=$ENV_LEGO_RENEW_HOOK"; fi
    else
        op=" run"
        if [[ -n "$ENV_LEGO_RUN_HOOK" ]]; then op="$op --run-hook=$ENV_LEGO_RUN_HOOK"; fi
    fi

    # Challenge types
    if [[ -n "$ENV_LEGO_HTTP" ]] && [[ "$ENV_LEGO_HTTP" = "true" ]]; then
        args="$args --http"
    fi
    if [[ -n "$ENV_LEGO_DNS" ]]; then
        args="$args --dns=$ENV_LEGO_DNS"
    fi

    if [[ -n "$ENV_LEGO_ACCEPT_TOS" ]] && [[ "$ENV_LEGO_ACCEPT_TOS" = "true" ]]; then
        args="$args --accept-tos"
    fi

    # General options
    if [[ -n "$ENV_LEGO_EMAIL" ]]; then args="$args --email=$ENV_LEGO_EMAIL"; fi
    # TODO: add support for a domain list
    if [[ -n "$ENV_LEGO_DOMAINS" ]]; then args="$args --domains=$ENV_LEGO_DOMAINS"; fi
    if [[ -n "$ENV_LEGO_SERVER" ]]; then args="$args --server=$ENV_LEGO_SERVER"; fi
    if [[ -n "$ENV_LEGO_CSR" ]]; then args="$args --csr=$ENV_LEGO_CSR"; fi

    # Additional arguments
    if [[ -n "$ENV_LEGO_ARGS" ]]; then args="$args$ENV_LEGO_ARGS"; fi

    set -- lego $args$op
fi

exec "$@"
