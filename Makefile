build:
	docker build \
		-t joseluisq/docker-lets-encrypt:latest \
		-f Dockerfile .
.PHONY: build

run:
	docker run -it --rm joseluisq/docker-lets-encrypt:latest bash
.PHONY: run
