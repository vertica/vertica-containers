# Makefile for vertica-demo

VERTICA_INSTALL?=/opt/vertica
VERTICA_VERSION?=latest
VERSION?=latest
SHELL:=/bin/bash

help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' "$(firstword $(MAKEFILE_LIST))"

java: $(VERTICA_INSTALL)/java ## copy the local install of the java libraries
	cp -r $< $@

kafka: $(VERTICA_INSTALL)/packages/kafka ## copy the local install of the kafka scheduler
	cp -r $< $@

.PHONY: build
build: java kafka ## build the docker image
	docker build . -t vertica/kafka-scheduler

.PHONY: push
push: java kafka ## push the docker image up to docker hub
	docker context create mycontext; \
	docker buildx create mycontext -name mybuilder; \
	docker buildx inspect --bootstrap; \
	docker buildx build --platform=linux/arm64,linux/amd64 -t "vertica/kafka-scheduler:$(VERTICA_VERSION)" . --push

.PHONY: test
test: ## suite of tests to make sure everything is working
	docker run vertica/kafka-scheduler vkconfig --help >/dev/null
	./example.sh
