# Makefile for vertica-demo

VERTICA_INSTALL?=/opt/vertica
VERTICA_VERSION?=$(shell perl -nE 'my $$v=$$1 if m/Version\s*=\s*"v([\d\.]*)-/; END { say $$v||"latest" }' /opt/vertica/sdk/BuildInfo.java 2>/dev/null || echo "latest")
TAGS=$(patsubst %,-t vertica/kafka-scheduler:%,$(VERTICA_VERSION))
SHELL:=/bin/bash

help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' "$(firstword $(MAKEFILE_LIST))"

.PHONY: build
version: ## display the Vertica version to use (override with VERTICA_VERSION)
	@echo $(VERTICA_VERSION)

java: $(VERTICA_INSTALL)/java ## copy the local install of the java libraries
	cp -r $< $@

kafka: $(VERTICA_INSTALL)/packages/kafka ## copy the local install of the kafka scheduler
	cp -r $< $@

.PHONY: build
build: java kafka ## build the docker image
	docker build . -t vertica/kafka-scheduler:$(word 1,$(VERTICA_VERSION))

.PHONY: push
push: java kafka ## push the docker image up to docker hub
	#docker context create mycontext
	docker buildx rm vkconfig_builder >/dev/null 2>&1 || true
	docker buildx create --use --driver docker-container --name vkconfig_builder
	docker buildx inspect --bootstrap
	docker buildx build --platform=linux/arm64,linux/amd64 $(TAGS) . --push
	docker buildx rm vkconfig_builder >/dev/null 2>&1 || true

.PHONY: test
test: ## suite of tests to make sure everything is working
	VERTICA_VERSION=$(word 1,$(VERTICA_VERSION)) ./example.sh

.PHONY: clean
clean: ## clean up local directory and docker image created by "make build"
	rm -rf java kafka
	docker image rm vertica/kafka-scheduler:$(word 1,$(VERTICA_VERSION))
