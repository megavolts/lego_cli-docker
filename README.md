# Docker Let's Encrypt

> A [Let's Encrypt](https://letsencrypt.org/) Docker image using [Lego CLI](https://go-acme.github.io/lego/) client on top of the latest __Debian [12-slim](https://hub.docker.com/_/debian/tags?page=1&name=12-slim)__ ([Bookworm](https://www.debian.org/News/2023/20230610)).

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

## Environment variables

The image provides environment variables support for several [Lego CLI](https://go-acme.github.io/lego/usage/cli/) arguments.

Below are the environment variables supported and their default values.

### Active environment variables support

To activate the environment variables support, set `ENV_LEGO_ENABLE=true`.

- `ENV_LEGO_ENABLE=false`

### General options

- `ENV_LEGO_EMAIL`
- `ENV_LEGO_DOMAINS`
- `ENV_LEGO_SERVER`
- `ENV_LEGO_CSR`
- `ENV_LEGO_RUN_HOOK`

### Challenge types

- `ENV_LEGO_HTTP=false`
- `ENV_LEGO_DNS`

### Obtain a new certificate

By default, the **Lego CLI** `run` subcomand will be executed, which will [obtain a new certificate](https://go-acme.github.io/lego/usage/cli/obtain-a-certificate/).

### Renew existing certificate

To [renew a certificate](https://go-acme.github.io/lego/usage/cli/renew-a-certificate/), use the following environment variables instead.

- `ENV_LEGO_RENEW=false`
- `ENV_LEGO_RENEW_DAYS`

### Additional arguments

- `ENV_LEGO_ARGS`

```sh
docker run --rm joseluisq/docker-lets-encrypt -h
```

For more details check out the [Lego CLI](https://go-acme.github.io/lego/usage/cli/) available options.

## Contributions

Unless you explicitly state otherwise, any contribution intentionally submitted for inclusion in current work by you, as defined in the Apache-2.0 license, shall be dual licensed as described below, without any additional terms or conditions.

Feel free to send some [Pull request](https://github.com/joseluisq/docker-lets-encrypt/pulls) or file an [issue](https://github.com/joseluisq/docker-lets-encrypt/issues).

## License

This work is primarily distributed under the terms of both the [MIT license](LICENSE-MIT) and the [Apache License (Version 2.0)](LICENSE-APACHE).

© 2024-present [Jose Quintana](https://joseluisq.net)
