FROM --platform=$BUILDPLATFORM debian:12.5-slim as build

ARG TARGETPLATFORM
ARG VERSION=0.0.0
ENV VERSION=${VERSION}

ARG LEGO_VERSION=4.16.1
ENV LEGO_VERSION=${LEGO_VERSION}

RUN set -eux \
    && DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && DEBIAN_FRONTEND=noninteractive apt-get install -qq -y --no-install-recommends --no-install-suggests \
         ca-certificates \
         curl \
         file \
         tzdata \
    && true

RUN set -ex \
    && case "$TARGETPLATFORM" in \
        "linux/amd64") target='linux_amd64' ;; \
        "linux/arm64") target='linux_arm64' ;; \
        "linux/386") target='linux_386' ;; \
        "linux/arm/v7") target='linux_armv7' ;; \
        "linux/arm/v6") target='linux_armv6' ;; \
        *) echo >&2 "error: unsupported $TARGETPLATFORM architecture"; exit 1 ;; \
    esac \
    && curl -Lo /tmp/lego.tar.gz \
        "https://github.com/go-acme/lego/releases/download/v${LEGO_VERSION}/lego_v${LEGO_VERSION}_${target}.tar.gz" \
    && tar xzvf /tmp/lego.tar.gz \
    && cp lego /usr/local/bin/ \
    && rm -rf /tmp/lego.tar.gz \
    && chmod +x /usr/local/bin/lego \
    && true

RUN set -ex \
    && echo "Testing Docker image..." \
    && uname -a \
    && cat /etc/os-release \
    && echo VERSION_NUMBER=$(cat /etc/debian_version) \
    && file /usr/local/bin/lego \
    && lego --version \
    && lego --help \
    && true

FROM debian:12.5-slim

ARG VERSION=0.0.0
ENV VERSION=${VERSION}

LABEL version="${VERSION}" \
    description="A Let's Encrypt Docker image using Lego CLI client." \
    maintainer="Jose Quintana <joseluisq.net>"

# General options
ENV ENV_LEGO_EMAIL=
ENV ENV_LEGO_DOMAINS=
ENV ENV_LEGO_SERVER=
ENV ENV_LEGO_CSR=
ENV ENV_LEGO_ACCEPT_TOS=false
ENV ENV_LEGO_PATH=/etc/ssl/.lego

# Challenge types
ENV ENV_LEGO_HTTP=false
# See Lego DNS providers supported https://go-acme.github.io/lego/dns/#dns-providers
ENV ENV_LEGO_DNS=

# Run hooks
ENV ENV_LEGO_RUN_HOOK=

# Specify if the operation will be a `renewal`
ENV ENV_LEGO_RENEW=false
ENV ENV_LEGO_RENEW_DAYS=
ENV ENV_LEGO_RENEW_HOOK=

# Certificate auto-renew feature
ENV ENV_CERT_AUTO_RENEW=false
# Renew the certificate 3 days before expiration
ENV ENV_CERT_AUTO_RENEW_DAYS_BEFORE_EXPIRE=3
# Check certificate expiration once a day by default
ENV ENV_CERT_AUTO_RENEW_CRON_INTERVAL="0 0 * * *"

RUN set -eux \
    && DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && DEBIAN_FRONTEND=noninteractive apt-get install -qq -y --no-install-recommends --no-install-suggests \
         ca-certificates \
         cron \
         tzdata \
    # Clean up local repository of retrieved packages and remove the package lists
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && true

COPY --from=build /usr/local/bin/lego /usr/local/bin/
COPY ./entrypoint.sh /usr/local/bin/
COPY ./certificate_renew.sh /usr/local/bin/

ENTRYPOINT ["entrypoint.sh"]

CMD ["lego"]

# Metadata
LABEL org.opencontainers.image.vendor="Jose Quintana" \
    org.opencontainers.image.url="https://github.com/joseluisq/docker-lets-encrypt" \
    org.opencontainers.image.title="Docker Let's Encrypt" \
    org.opencontainers.image.description="A Let's Encrypt Docker image using Lego CLI client." \
    org.opencontainers.image.version="${VERSION}" \
    org.opencontainers.image.documentation="https://github.com/joseluisq/docker-lets-encrypt"
