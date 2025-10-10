ARG BUILD_NAME="Lego CLI client" \
    BUILD_DESCRIPTION="CLI client of Let's Encrypt/ACME client and library written in Go" \
    BUILD_REPOSITORY="megavolts/lego_cli" \
    ALPINE_VERSION="latest" \
    BUILD_IMAGE_VERSION

# Stage 1 - install lego as buildplatform
FROM --platform=$BUILDPLATFORM alpine:$ALPINE_VERSION AS buildenv

ARG TARGETPLATFORM \
    BUILD_IMAGE_VERSION

# Set shell
SHELL ["/bin/ash", "-o", "pipefail", "-c"]

RUN apk --update --no-cache add \
        ca-certificates \
        curl \
        file \
        tzdata \
        openssl
        
# 1.1 Install lego
RUN echo "Installing lego for $TARGETPLATFORM..." \
    && case "$TARGETPLATFORM" in \
        "linux/amd64") ARCH='linux_amd64' ;; \
        "linux/arm64") ARCH='linux_arm64' ;; \
        "linux/386") ARCH='linux_386' ;; \
        "linux/arm/v7") ARCH='linux_armv7' ;; \
        "linux/arm/v6") ARCH='linux_armv6' ;; \
        *) echo >&2 "[error] unsupported $TARGETPLATFORM architecture"; exit 1 ;; \
    esac \
    && LEGO_VERSION=$( echo $BUILD_IMAGE_VERSION | cut -d- -f1 ) \
    # for debug
    && echo "lego version: $LEGO_VERSION for $ARCH" \
    && echo "Downloading: https://github.com/go-acme/lego/releases/download/v${LEGO_VERSION}/lego_v${LEGO_VERSION}_${ARCH}.tar.gz" \
    && curl -L "https://github.com/go-acme/lego/releases/download/v${LEGO_VERSION}/lego_v${LEGO_VERSION}_${ARCH}.tar.gz" \
            -o lego.tar.gz \
    && tar -zxf lego.tar.gz -C /usr/local/bin/ lego \
    && chmod +x /usr/local/bin/lego \
    && rm -rf lego.tar.gz

# 1.2 Check lego install
RUN echo "Testing docker image..." \
    && uname -a \
    && cat /etc/os-release \
    && echo VERSION_NUMBER=$(cat /etc/alpine-release ) \
    && file /usr/local/bin/lego \
    && lego --version \
    && lego --help

# 1.3 Configure lego_cli 
COPY rootfs/ /
RUN echo "Make entrypoint and renewal scrips executable..." \
    && chmod 755 /usr/local/bin/entrypoint.sh \
    && chmod 755 /opt/lego/renew_certificate.sh

# Stage 2 - build for target platform
FROM  alpine:$ALPINE_VERSION AS lego

ARG BUILD_IMAGE_VERSION \
    BUILD_REPOSITORY \
    BUILD_DESCRIPTION \
    BUILD_IMAGE_VERSION \
    BUILD_NAME \
    BUILD_TITLE 

ENV BUILD_IMAGE_VERSION="${BUILD_IMAGE_VERSION}"

# General options
ENV LEGO_EMAIL= \
    LEGO_DOMAINS= \
    LEGO_SERVER="https://acme-v02.api.letsencrypt.org/directory" \
    LEGO_CSR= \
    LEGO_ACCEPT_TOS="true" \
    LEGO_PATH="/opt/lego/ssl" \
# Staging option
    STAGING="false" \
# Certificate autorenewal option
    AUTORENEW="true" \
    # Number of day before certificate expiration when renewal attempt should start.
    # Default: 3 days
    AUTORENEW_PERIOD="3" \
    # Cron job schedule to check certificate expiration
    # Default: at midnight, everyday
    AUTORENEW_CRON_SCHEDULE="0 */24 * * *" \
# Challenge types
   # HTTP. Default: false
   LEGO_HTTP=false \
   # DNS. 
   # Supported DNS providers: https://go-acme.github.io/lego/dns/#dns-providers
   LEGO_DNS= \
# Renew certificate using the dynamic option, which is default behavior on upcoming
# lego v5 release.
    LEGO_RENEW="false"

RUN apk --update --no-cache add \
        ca-certificates \
        tzdata \
    # Clean temprorary file and package cache
    && rm -rf /tmp/* /var/cache/apk/*

# Copy lego binary and opt files from buildenv
COPY --from=buildenv /usr/local/bin/lego /usr/local/bin/entrypoint.sh /bin/
COPY --from=buildenv /opt /opt
COPY --from=buildenv /usr/bin/openssl /usr/bin

ENTRYPOINT ["entrypoint.sh"]

CMD ["lego"]

LABEL org.opencontainers.image.vendor="Marc Oggier" \
      org.opencontainers.image.url="https://github.com/"${BUILD_REPOSITORY}"-docker" \
      org.opencontainers.image.title="$BUILD_NAME" \
      org.opencontainers.image.description="$BUILD_DESCRIPTION" \
      org.opencontainers.image.version="$($BUILD_IMAGE_VERSION | cut -d- -f1)" \
      org.opencontainers.image.documentation="https://github.com/"${BUILD_REPOSITORY}"-docker"