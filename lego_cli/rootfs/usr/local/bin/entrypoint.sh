#!/bin/ash
# docs: https://go-acme.github.io/lego/usage/cli/
# Path: /opt/entrypoint.sh

set -e

INPUT=$1

if $DEBUG ; then
    echo "[debug] Debug mode enabled"
fi

# Check if incoming command contains flags
if [[ "${1#-}" != "$INPUT" ]] && [[ "$INPUT" != "--certificate-renew" ]];
    then
    set -- lego "$@"
elif [[ -n "$LEGO_ENABLE" ]] && [[ "$LEGO_ENABLE" = "true" ]];
    then
    args=""
    op=""

    # Renew operation on demand which also skip auto-renew when file called directly
    if [[ -n "$INPUT" ]] && [[ "$INPUT" = "--certificate-renew" ]];
        then
        LEGO_RENEW=true
    fi

    # Operation types, the default is `run` subcommand
    if [[ -n "$LEGO_RENEW" ]] && [[ "$LEGO_RENEW" = "true" ]];
        then
        op=" renew --dynamic"
    else
        op=" run"
    fi
    
    if [[ -n "$LEGO_PATH" ]];
        then
        mkdir -p $LEGO_PATH       
        args="$args --path=$LEGO_PATH"
    fi

    # Challenge types
    if [[ -n "$LEGO_HTTP" ]] && [[ "$LEGO_HTTP" = "true" ]];
        then
        args="$args --http"
    fi
    if [[ -n "$LEGO_DNS" ]];
        then
        args="$args --dns=$LEGO_DNS"
    fi

    # Term of services
    if [[ "$LEGO_ACCEPT_TOS" = "true" ]];
        then
        args="$args --accept-tos"
    fi

    # General options
    if [[ -n "$LEGO_EMAIL" ]];
        then
        args="$args --email=$LEGO_EMAIL"
    fi
    
    if [[ -n "$LEGO_DOMAINS" ]];
        then
        for domain in $(echo $LEGO_DOMAINS | tr "," " ")
        do 
            args="$args --domains=$domain" 
        done
    fi

    if [[ -n "$LEGO_SERVER" ]] && $STAGING ;
        then
        echo "[warn] Staging and server option cannot specified at the same time."
        echo "       Forcing staging option with server --server=https://acme-staging-v02.api.letsencrypt.org/directory"
        LEGO_SERVER="https://acme-staging-v02.api.letsencrypt.org/directory"
    elif $STAGING ;
        then
        echo "[warn] Enabling staging with default server"
        LEGO_SERVER="https://acme-staging-v02.api.letsencrypt.org/directory"
    fi

    if [[ -n "$LEGO_SERVER" ]];
        then
        args="$args --server=$LEGO_SERVER"
    fi

    if [[ -n "$LEGO_CSR" ]];
        then
        args="$args --csr=$LEGO_CSR"
    fi

    # Additional arguments
    if [[ -n "$LEGO_ARGS" ]];
        then
        args="$args$LEGO_ARGS"
    fi
    set -- lego $args$op

    ## Enable autorenewal at start up time
    # NOTE: `LEGO_RENEW` should not be forced to renew a certificate at the same time as enabling
    # the autorenewal feature
    if [[ -z "$LEGO_RENEW" ]] || [[ "$LEGO_RENEW" = "false" ]]; 
        then
        if [[ -n "$AUTORENEW" ]] && [[ "$AUTORENEW" = "true" ]];
            then

            # 1. If a certificate does not exist, a certificate is requested
            # NOTE: If a domain list is provided, the certificate is named after the first domain
            domain=$(echo $LEGO_DOMAINS | sed 's/,.*//' | sed 's/;.*//' | sed 's/*.//')
            cert_file=$LEGO_PATH/certificates/$domain.crt
            # TODO: check that the certificate covers all the domains
            if [ -f $cert_file ];
                then
                echo "[info] A certificate file exist '$cert_file' was found. No new certificate is requested"
            else
                echo "[info] Requesting a new certificate"
                lego $args$op
            fi

            # 2. Configure the Crontab task and redirect its output to Docker stdout
            echo
            echo "[info] Adding autorenewal task as a cronjob"
            echo "LEGO_DOMAINS=$LEGO_DOMAINS" > $LEGO_PATH/certificates/.$domain-crontab.env
            echo "AUTORENEW_PERIOD=$AUTORENEW_PERIOD" >> $LEGO_PATH/certificates/.$domain-crontab.env
            echo "DEBUG=$DEBUG" >> $LEGO_PATH/certificates/.$domain-crontab.env
            echo "LEGO_RENEW=$LEGO_RENEW" >> $LEGO_PATH/certificates/.$domain-crontab.env
            cmd="SHELL=/bin/ash BASH_ENV=$LEGO_PATH/certificates/.$domain-crontab.env /opt/lego/renew_certificate.sh > /proc/1/fd/1 2>&1"
            crontab -l | echo "$AUTORENEW_CRON_SCHEDULE $cmd" | crontab -
            echo "[info] The Crontab task is configure with the schedule $AUTORENEW_CRON_SCHEDULE"
            if $DEBUG ; then
                echo "[debug] Checking crontab"
                echo "$(crontab -l)"
            fi
            
            # Make sure the certificate are accessible outside of the container by a non-root user
            # Use ` && tail -f /dev/null` to let the container running
            chmod 555 $LEGO_PATH -R && tail -f /dev/null
            exit
        fi
    fi
fi
# Make sure the certificate are accessible outside of the container by a non-root user
echo "$@"
exec "$@"