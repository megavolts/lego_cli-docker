#!/bin/ash
# Scripts to renew certificate before expiration run by a crontb
# Original script by Jose Quintana (https://github.com/joseluisq/docker-lets-encrypt/blob/master/certificate_renew.sh)

echo "[info] Starting certificate check script..."

# NOTE: The `LEGO_RENEW` triggers a lego CLI renewal operation with the command
# `lego [global options] renew [command options]`, and should not be enable fot
# the autorenewal to complete successfuly.
if [[ -n "$LEGO_RENEW" ]] && [[ "$LEGO_RENEW" = "true" ]]; then
    echo "[warn] LEGO_RENEW should be disabled when using auto-renew. Nothing happens."
    exit
fi

# Check for required environment variable
if [[ -z "$LEGO_DOMAINS" ]];
    then
    echo "[warn:autorenewal] LEGO_DOMAINS is required, but not provided. Nothing happens."
    exit
elif [[ -z "$AUTORENEW_PERIOD" ]];
    then
    echo "[warn:autorenewal] AUTORENEW_PERIOD is not provided. Nothing happens."
    exit
else
    if [[ $DEBUG ]];
    then
    echo "[debug:autorenewal] All requirement for autorenewal are fullfilled."
fi

# Find the cert file based on `LEGO_DOMAINS`
# NOTE: If a domain list was provided, the certificate is named after the first domain
domain=$(echo $ENV_LEGO_DOMAINS | sed 's/;.*//' | sed 's/*.//')
cert_file=$ENV_LEGO_PATH/certificates/$domain.crt

if $DEBUG ; then
    echo "[debug:autorenewal] Processing autorenewal for $domain"
fi

if [ ! -f $cert_file ]; then
    echo "[warn:autorenewal] The certificate file '$cert_file' was not found. Nothing happens."
    continue
fi

end_date=$(openssl x509 -in $cert_file -noout -enddate | sed 's/;.*//' | sed 's/notAfter=//')
end_date_timestamp=$(date -d "$end_date" +"%s")
end_date_before_expire=$(date -d "$end_date $AUTORENEW_PERIOD days ago" +"%s")
current_time=$(date +%s)

# DEBUG: enable this when testing
if $DEBUG ; then
    current_time=$(date -d "+90 days" +%s)
fi

echo "[info:autorenewal] Checking if certificate is closer to expire..."
echo "                   Cert File: $cert_file"
echo "                   Current End Date: $end_date | End Date Timestamp=$end_date_timestamp"
echo "                   Renew Before: $AUTORENEW_PERIOD day(s)"

# Checking certificate expiration
if [ $current_time -lt $end_date_before_expire ]; then
    echo "[info:autorenewal] The certificate is still valid until $end_date. Nothing to do."
    continue
fi

# Certificated closer to expire, try to renew it
echo "[warn:autorenewal] The certificate is closer to expire on $end_date"
echo "[info:autorenewal] Trying to renew the certificate before expire..."
echo

# Renew the certificate
/bin/entrypoint.sh --certificate-renew

end_date=$(openssl x509 -in $cert_file -noout -enddate | sed 's/;.*//' | sed 's/notAfter=//')
end_date_timestamp=$(date -d "$end_date" +"%s")

echo "[info:autorenewal] The certificate renewal was performed successfully!"
echo "                   Cert File: $cert_file"
echo "                   New End Date: $end_date | End Date Timestamp=$end_date_timestamp"
echo
done