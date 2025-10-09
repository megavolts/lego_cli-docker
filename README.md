# Docker Let's Encrypt 

<a href="https://github.com/joseluisq/docker-lets-encrypt/actions/workflows/devel.yml" title="devel ci"><img src="https://github.com/joseluisq/docker-lets-encrypt/actions/workflows/devel.yml/badge.svg?branch=master"></a> 
<a href="https://hub.docker.com/r/joseluisq/docker-lets-encrypt/" title="Docker Image Version (tag latest semver)"><img src="https://img.shields.io/docker/v/joseluisq/docker-lets-encrypt/latest"></a> 
<a href="https://hub.docker.com/r/joseluisq/docker-lets-encrypt/tags" title="Docker Image Size (tag)"><img src="https://img.shields.io/docker/image-size/joseluisq/docker-lets-encrypt/latest"></a> 
<a href="https://hub.docker.com/r/joseluisq/docker-lets-encrypt/" title="Docker Image"><img src="https://img.shields.io/docker/pulls/joseluisq/docker-lets-encrypt.svg"></a> 

> A multi-arch [Let's Encrypt](https://letsencrypt.org/) Docker image using [Lego CLI](https://go-acme.github.io/lego/) client with convenient environment variables and auto-renewal support on top of the latest __Debian [12-slim](https://hub.docker.com/_/debian/tags?page=1&name=12-slim)__ ([Bookworm](https://www.debian.org/News/2023/20230610)).

## Usage

Run the Docker image

```sh
# Run Lego CI directly with a particular argument
docker run --rm joseluisq/docker-lets-encrypt -v

# Or run the Docker image in interactive mode
docker run -it --rm joseluisq/docker-lets-encrypt bash
```

Or extend it

```Dockerfile
FROM joseluisq/docker-lets-encrypt
# your stuff...
```

## Examples

Below is an example of obtaining a **wildcard certificate** using the **Cloudflare** provider.

In this case, make sure to create first a [Cloudflare API User Token](https://developers.cloudflare.com/fundamentals/api/get-started/create-token/) for your specific domain with the `DNS:Edit` permission.

### Using Docker run

```sh
docker run -it --rm \
    # Lego CLI options
    -e ENV_LEGO_ENABLE=true \
    -e ENV_LEGO_ACCEPT_TOS=true \
    -e ENV_LEGO_EMAIL=email@domain.com \
    -e ENV_LEGO_DOMAINS="*.domain.com" \
    # Lego CLI DNS provider
    -e ENV_LEGO_DNS=cloudflare \
    -e CLOUDFLARE_EMAIL=email@domain.com \
    -e CLOUDFLARE_DNS_API_TOKEN= \
    # TLS auto-renewal feature (optional)
    -e ENV_CERT_AUTO_RENEW=true \
    -e ENV_CERT_AUTO_RENEW_CRON_INTERVAL="0 0 * * *" \
    # Directory mapping (bind mount) for certificate/key files
    -v /etc/ssl/certs/domain.com:/etc/ssl/.lego \
    joseluisq/docker-lets-encrypt

# 2024/01/01 00:00:30 [INFO] [*.domain.com] acme: Obtaining bundled SAN certificate
# 2024/01/01 00:00:31 [INFO] [*.domain.com] AuthURL: https://acme-v02.api.letsencrypt.org/acme/authz-v3/000000000000
# 2024/01/01 00:00:31 [INFO] [*.domain.com] acme: use dns-01 solver
# 2024/01/01 00:00:31 [INFO] [*.domain.com] acme: Preparing to solve DNS-01
# 2024/01/01 00:00:31 [INFO] Found CNAME entry for "_acme-challenge.domain.com.": "dns.domain.com."
# 2024/01/01 00:00:32 [INFO] cloudflare: new record for domain.com, ID 1234567a8e000d0ab0ced00fgjk123e
# 2024/01/01 00:00:32 [INFO] [*.domain.com] acme: Trying to solve DNS-01
# 2024/01/01 00:00:32 [INFO] Found CNAME entry for "_acme-challenge.domain.com.": "dns.domain.com."
# 2024/01/01 00:00:32 [INFO] [*.domain.com] acme: Checking DNS record propagation. [nameservers=127.0.0.2:00]
# 2024/01/01 00:00:34 [INFO] Wait for propagation [timeout: 2m0s, interval: 2s]
# 2024/01/01 00:00:40 [INFO] [*.domain.com] The server validated our request
# 2024/01/01 00:00:40 [INFO] [*.domain.com] acme: Cleaning DNS-01 challenge
# 2024/01/01 00:00:40 [INFO] Found CNAME entry for "_acme-challenge.domain.com.": "dns.domain.com."
# 2024/01/01 00:00:41 [INFO] [*.domain.com] acme: Validations succeeded; requesting certificates
# 2024/01/01 00:00:42 [INFO] [*.domain.com] Server responded with a certificate.
```

**Notes:**

- `ENV_LEGO_ACCEPT_TOS=true` is used to accept the [Let's Encrypt terms of service](https://community.letsencrypt.org/tos).
- The container `.lego` directory will contain the certificates and keys, make sure to bind it to a specific host directory. See https://go-acme.github.io/lego/usage/cli/general-instructions/
- See the **Cloudflare** provider options for more details https://go-acme.github.io/lego/dns/cloudflare/

### Using Docker Compose

Below is an equivalent example like above but using [Docker Compose](https://docs.docker.com/compose/intro/features-uses/).

```yaml
version: "3.3"

services:
  joseluisq-net:
    image: joseluisq/docker-lets-encrypt:0.0.3
    environment:
      # Lego CLI options
      - "ENV_LEGO_ENABLE=true"
      - "ENV_LEGO_ACCEPT_TOS=true"
      - "ENV_LEGO_EMAIL=${ENV_LEGO_EMAIL}"
      - "ENV_LEGO_DOMAINS=*.domain.com"
      # Lego CLI DNS provider
      - "ENV_LEGO_DNS=cloudflare"
      - "CLOUDFLARE_EMAIL=${CLOUDFLARE_EMAIL}"
      - "CLOUDFLARE_DNS_API_TOKEN=${CLOUDFLARE_DNS_API_TOKEN}"
      # TLS auto-renewal feature (optional)
      - "ENV_CERT_AUTO_RENEW=true"
      - "ENV_CERT_AUTO_RENEW_CRON_INTERVAL=0 0 * * *"
    volumes:
      # Directory mapping (bind mount) for certificate/key files
      - /etc/ssl/certs/domain.com:/etc/ssl/.lego
    deploy:
      replicas: 1
      update_config:
        parallelism: 1
      restart_policy:
        condition: on-failure
```

## Environment variables

The image provides environment variables support for several [Lego CLI](https://go-acme.github.io/lego/usage/cli/) arguments.

Below are the environment variables supported and their default values.

### Activation

To activate the environment variables support, set `ENV_LEGO_ENABLE=true`.

- `ENV_LEGO_ENABLE=false` 

### General options

- `ENV_LEGO_EMAIL`
- `ENV_LEGO_DOMAINS` List of domains, domain name should be comma separated without space: domain1,domain2...
- `ENV_LEGO_SERVER`
- `ENV_LEGO_CSR`
- `ENV_LEGO_ACCEPT_TOS=false`
- `ENV_LEGO_PATH=/etc/ssl/.lego` Directory to use for storing the data.
- `ENV_LEGO_STAGING=false` Set to true to enable staging which override default server with ACME staging
### Challenge types

- `ENV_LEGO_HTTP=false`
- `ENV_LEGO_DNS` See Lego DNS providers supported https://go-acme.github.io/lego/dns/#dns-providers

### Obtain a new certificate

- `ENV_LEGO_RUN_HOOK`

By default, the **Lego CLI** `run` subcommand will be executed, which will [obtain a new certificate](https://go-acme.github.io/lego/usage/cli/obtain-a-certificate/).

### Renew existing certificate

To [renew a certificate](https://go-acme.github.io/lego/usage/cli/renew-a-certificate/), use the following environment variables instead.

- `ENV_LEGO_RENEW=false` It tells Lego CLI to perform a `renewal` operation on demand.
- `ENV_LEGO_RENEW_DAYS`
- `ENV_LEGO_RENEW_HOOK`

#### Certificate auto-renew

**NOTE:** the auto-renew feature is limited to one domain for now.

- `ENV_CERT_AUTO_RENEW=false` Enable the auto-renew feature
- `ENV_CERT_AUTO_RENEW_DAYS_BEFORE_EXPIRE=3` The days before the certificate expiration to perform a renewal try.
- `ENV_CERT_AUTO_RENEW_CRON_INTERVAL=0 0 * * *` The Crontab interval for the auto-renew checker (default, once a day)

When the option is `ENV_CERT_AUTO_RENEW=true` then a script will programmatically check the certificate days before the expiration (`ENV_CERT_AUTO_RENEW_DAYS_BEFORE_EXPIRE`) and will perform a renewal try.
Keep in mind that `ENV_LEGO_RENEW` should be disabled (`false`) when using this feature because it refers to the Lego CLI `renew` operation (subcommand).

### Additional arguments

- `ENV_LEGO_ARGS`

Print all available Lego CLI options.

```sh
# global options
docker run --rm joseluisq/docker-lets-encrypt -h
# or specific subcommand options
docker run --rm joseluisq/docker-lets-encrypt lego run -h
```

For more details check out the [Lego CLI](https://go-acme.github.io/lego/usage/cli/) available options.

## Contributions

Unless you explicitly state otherwise, any contribution intentionally submitted for inclusion in current work by you, as defined in the Apache-2.0 license, shall be dual licensed as described below, without any additional terms or conditions.

## Acknowledgement

This work is build upon [Jose Quintana](https://joseluisq.net)'s Let's Encrypt Docker.

Feel free to send some [Pull request](https://github.com/megavolts/lego_cli-docker/pulls) or file an [issue](https://github.com/megavolts/lego_cli-docker/issues).

# License

## License

Unless explicitly stated otherwise, this work is primarily distributed under the terms of both the [MIT license](LICENSE-MIT) and the [Apache License (Version 2.0)](LICENSE-APACHE).

## License for other compoents

- Docker: [Apache 2.0](https://github.com/docker/docker/blob/master/LICENSE)
- Lego: [MIT License](https://github.com/go-acme/lego/blob/master/LICENSE)
