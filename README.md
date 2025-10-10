Let's Encrypt GO CLI docker
================
![lego version](https://img.shields.io/github/v/release/go-acme/lego?label=go-acme%2Flego%20release)
![lego_cli version](https://img.shields.io/github/v/release/megavolts/lego_cli-docker?label=megavolts%2Flego_cli%20release)

<a href="https://hub.docker.com/r/megavolts/lego_cli/" title="Docker Image Version (tag latest semver)"><img src="https://img.shields.io/docker/v/megavolts/lego_cli/latest"></a> 
<a href="https://hub.docker.com/r/megavolts/lego_cli/tags" title="Docker Image Size (tag)"><img src="https://img.shields.io/docker/image-size/megavolts/lego_cli/latest"></a> 
<a href="https://hub.docker.com/r/megavolts/lego_cli/" title="Docker Image"><img src="https://img.shields.io/docker/pulls/megavolts/lego_cli.svg"></a> 
![CD BUILD](https://img.shields.io/github/actions/workflow/status/megavolts/lego_cli-docker/CD-30-tag_and_release.yml?branch=main&label=Build)

![Supports aarch64 Architecture](https://img.shields.io/badge/aarch64-yes-green)
![Supports amd64 Architecture](https://img.shields.io/badge/amd64-yes-green)
![Supports armv7 Architecture](https://img.shields.io/badge/armv7-yes-green)
![Supports armv6 Architecture](https://img.shields.io/badge/armv6-yes-green)
![Supports i386 Architecture](https://img.shields.io/badge/i386-yes-green)

![License](https://img.shields.io/badge/license-MIT-green)
![License](https://img.shields.io/badge/license-Apache-green)

> A multi-arch [Let's Encrypt](https://letsencrypt.org/) Docker image using [lego](https://go-acme.github.io/lego/) CLI client with convenient environment variables and auto-renewal support on top of the latest __[Alpine](https://hub.docker.com/_/alpine)__.

# Usage
Run the Docker image

```sh
# Run Lego CI directly with a particular argument
docker run --rm megavolts/lego_cli -v

# Or run the Docker image in interactive mode
docker run -it --rm megavolts/lego_cli /bin/sh
```


## Examples
Below is an example of obtaining a **wildcard certificate** using the **Porkbun** provider using the DNS challenge.

In this case, make sure to create first a [Porkbun API Token](https://kb.porkbun.com/article/190-getting-started-with-the-porkbun-api) for your account, and enable `API token` for the domain.

### Using Docker run
```sh
docker run -it --rm \
    # Lego CLI options
    -e LEGO_ENABLE=true \
    -e LEGO_ACCEPT_TOS=true \
    -e LEGO_EMAIL=${LEGO_EMAIL} \
    -e LEGO_DOMAINS=domain.tld,subdomain.domain.tld \
    # Lego CLI DNS provider for porkbun
    -e LEGO_DNS=porkbun \
    -e PORKBUN_API_KEY=${PORKBUN_API_KEY} \
    -e PORKBUN_SECRET_API_KEY=${PORKBUN_SECRET_API_KEY} \
    # Autorenewal option
    -e AUTORENEW=true \
    # Directory mapping (bind mount) for certificate/key files
    -v ./ssl:/opt/lego/ssl/
    megavolts/lego_cli:latest

```
> By default, `LEGO_ACCEPT_TOS` is set to true. By using this container you accept to accept the [Let's Encrypt terms of service](https://community.letsencrypt.org/tos).

**Notes:**
The container `/opt/lego/ssl/` directory will contain the certificates under `/opt/lego/ssl/certificates` and keys under `/opt/lego/ssl/certificates/accounts` make sure to bind it to a specific host directory. See https://go-acme.github.io/lego/usage/cli/general-instructions/

### Using Docker Compose
Below is an equivalent example like above but using [Docker Compose](https://docs.docker.com/compose/intro/features-uses/).

```yaml
services:
  lego_cli:
    container_name: lego
    image: megavolts/lego_cli:latest
    environment:
      # Lego CLI options
      - LEGO_ENABLE=true
      - LEGO_EMAIL=${LEGO_EMAIL}
      # Domains should be comma separated
      - LEGO_DOMAINS=domain.tld
      # Lego CLI DNS provider
      - LEGO_DNS=porkbun
      - PORKBUN_API_KEY=${PORKBUN_API_KEY}
      - PORKBUN_SECRET_API_KEY=${PORKBUN_SECRET_API_KEY}
      # TLS auto-renewal feature (optional)
      - AUTORENEW=true
    volumes:
      # Directory mapping (bind mount) for certificate/key files
      - ./ssl/:/opt/lego/ssl/
    deploy:
      replicas: 1
      update_config:
        parallelism: 1
      restart_policy:
        condition: unless-stopped
```

> By default this container set to accetp the current Let's ENcrypt terms of service, overriding the default config in lego.


## Environment variables
The image provides environment variables support for several [Lego CLI](https://go-acme.github.io/lego/usage/cli/) arguments.

Below are the environment variables supported and their default values.


### Activation
To activate the environment variables support, set `LEGO_ENABLE=true`.
- `LEGO_ENABLE=false` 


### General options
- `LEGO_EMAIL` Email used for registration and recovery contact.
- `LEGO_DOMAINS` Domain or list of domains to include in the certificate. Multiple domains can be specified using a comma separated list (e.g. domain1.tld,subdomain.domain1.tld,domain2.tld)
- `LEGO_SERVER=https://acme-v02.api.letsencrypt.org/directory` CA hostname (and optionally :port). The server certificate must be trusted in order to avoid further modifications to the client. By default, set to the ACME default server.
- `LEGO_CSR` Certificate signing request filename, if an external CSR is to be used.
- `LEGO_ACCEPT_TOS=true` By default, accept the current Let's Encrypt terms of service. 
- `LEGO_PATH=/opt/lego/ssl` Directory to use for storing the data.


### Staging
- `STAGING=false` By setting this flag to true, the staging option is enable, the `LEGO_SERVER` is override with the default Let's Encrypt staging server (https://acme-staging-v02.api.letsencrypt.org/directory).


### Challenge types

- `LEGO_HTTP=false` By setting this flag to true, use the HTTP-01 challenge to solve challenges. Can be mixed with other types of challenges.
- `LEGO_DNS` See Lego DNS providers supported https://go-acme.github.io/lego/dns/#dns-providers


### Obtain a new certificate
By default, the **Lego CLI** `run` subcommand will be executed, which will [obtain a new certificate](https://go-acme.github.io/lego/usage/cli/obtain-a-certificate/).

### Renew existing certificate
To [renew a certificate](https://go-acme.github.io/lego/usage/cli/renew-a-certificate/), use the following environment variables instead.

- `LEGO_RENEW=false` It tells Lego CLI to perform a `renewal` operation on demand.

This container uses the default behavior of the upcoming Lego v5 to compute dynamically when to renew the certificate based on the lifetime using hte `--dynamic` option. 

### Certificate Autorenewal
- `AUTORENEW=true` By setting this flg to false, disables the autorenewal feature
- `AUTORENEW_PERIOD=3` Number of days before the certificate expiration to perform a renewal try.
- `AUTORENEW_CRON_SCHEDULE=0 */24* * * *` The crontab schedule for the autorenewal checker (default, once every 24 hours)

When the option is `AUTORENEW=true` then a script will programmatically check the certificate days before the expiration (`AUTORENEW_PERIOD`) and will perform a renewal try. Note that setting `AUTORENEW=true` disables `LEGO_RENEW` should be disabled (`false`) when using this feature because it refers to the Lego CLI `renew` operation (subcommand).

### Additional arguments
- `LEGO_ARGS`

Print all available Lego CLI options.

```sh
# global options
docker run --rm megavolts/lego_cli -h
# or specific subcommand options
docker run --rm megavolts/lego_cli lego run -h
```
For more details check out the [Lego CLI](https://go-acme.github.io/lego/usage/cli/) available options.

# Contributions
Unless you explicitly state otherwise, any contribution intentionally submitted for inclusion in current work by you, as defined in the Apache-2.0 license, shall be dual licensed as described below, without any additional terms or conditions.


# Acknowledgements
This work is build upon [Jose Quintana](https://joseluisq.net)'s Let's Encrypt Docker.

Feel free to send some [Pull request](https://github.com/megavolts/lego_cli-docker/pulls) or file an [issue](https://github.com/megavolts/lego_cli-docker/issues).

# Licenses
## License
Unless explicitly stated otherwise, this work is primarily distributed under the terms of both the [MIT license](LICENSE-MIT) and the [Apache License (Version 2.0)](LICENSE-APACHE).

## License for other compoents
- Docker: [Apache 2.0](https://github.com/docker/docker/blob/master/LICENSE)
- Lego: [MIT License](https://github.com/go-acme/lego/blob/master/LICENSE)
