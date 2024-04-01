#!/bin/bash

#
# Custom script to renew a certificate before it expires.
# This script will be run by a cron-tab to check for the certificate expiration programmatically.
#

echo "[info] Starting certificate check script..."

# NOTE: The `ENV_LEGO_RENEW` specifies only a Lego CLI renewal operation
# so we only proceed if it is disabled
if [[ -n "$ENV_LEGO_RENEW" ]] && [[ "$ENV_LEGO_RENEW" = "true" ]]; then
    echo "[warn] ENV_LEGO_RENEW should be disabled when using auto-renew. Cancelled!"
    exit
fi
# Required envs
if [[ -z "$ENV_LEGO_DOMAINS" ]]; then
    echo "[warn] ENV_LEGO_DOMAINS is required by not provided. Cancelled!"
    exit
fi
if [[ -z "$ENV_CERT_AUTO_RENEW" ]] || [[ "$ENV_CERT_AUTO_RENEW" != "true" ]]; then
    echo "[warn] ENV_CERT_AUTO_RENEW is required by not provided. Cancelled!"
    exit
fi
if [[ -z "$ENV_CERT_AUTO_RENEW_DAYS_BEFORE_EXPIRE" ]]; then
    echo "[warn] ENV_CERT_AUTO_RENEW_DAYS_BEFORE_EXPIRE is required by not provided. Cancelled!"
    exit
fi

# TODO: Add support for multiple domains

# Find the cert file based on `ENV_LEGO_DOMAINS`
# NOTE: The auto-renew feature is limited to one domain for now
domain=$(echo $ENV_LEGO_DOMAINS | sed 's/;.*//' | sed 's/*.//')
cert_file=$ENV_LEGO_PATH/certificates/_.$domain.crt

if [ ! -f $cert_file ]; then
    echo "[warn] The certificate file '$cert_file' was not found. Cancelled!"
    exit
fi

end_date=$(openssl x509 -in $cert_file -noout -enddate | sed 's/;.*//' | sed 's/notAfter=//')
end_date_timestamp=$(date -d "$end_date" +"%s")
end_date_before_expire=$(date -d "$end_date $ENV_CERT_AUTO_RENEW_DAYS_BEFORE_EXPIRE days ago" +"%s")
current_time=$(date +%s)
# DEBUG: enable this when testing
# current_time=$(date -d "+90 days" +%s)

echo "[info] Checking if certificate is closer to expire..."
echo "[info]       Cert File: $cert_file"
echo "[info]        End Date: $end_date | End Date Timestamp=$end_date_timestamp"
echo "[info]    Renew Before: $ENV_CERT_AUTO_RENEW_DAYS_BEFORE_EXPIRE day(s)"

# Checking certificate expiration
if [ $current_time -lt $end_date_before_expire ]; then
    echo "[info] The certificate is still valid until $end_date. Nothing to do."
    exit
fi

# Certificated closer to expire, try to renew it

echo "[warn] The certificate is closer to expire on $end_date"
echo "[info] Trying to renew the certificate before expire..."
echo

/usr/local/bin/entrypoint.sh --certificate-renew

echo "[info] The certificate renewal was performed successfully!"
end_date=$(openssl x509 -in $cert_file -noout -enddate | sed 's/;.*//' | sed 's/notAfter=//')
end_date_timestamp=$(date -d "$end_date" +"%s")
echo "[info]       Cert File: $cert_file"
echo "[info]        End Date: $end_date | End Date Timestamp=$end_date_timestamp"
echo
