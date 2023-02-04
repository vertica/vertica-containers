# Makefile for vertica-demo

help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' "$(firstword $(MAKEFILE_LIST))"

ifdef PACKAGE

VERTICA_UNPACKED=$(patsubst %.rpm,%,$(basename $(PACKAGE)))
VERTICA_INSTALL=$(VERTICA_UNPACKED)/opt/vertica
VERTICA_VERSION=v$(firstword $(subst -, ,$(patsubst vertica_%,%,$(patsubst vertica-%,%,$(basename $(PACKAGE))))))
$(VERTICA_INSTALL): $(PACKAGE) ## Unpack $PACKAGE
	rm -rf $(VERTICA_UNPACKED); \
	mkdir -p $(VERTICA_UNPACKED); \
	if type -p rpm2cpio >/dev/null; then \
	  if ! (cd $(VERTICA_UNPACKED); rpm2cpio $(abspath $(PACKAGE)) | cpio -idm); then \
	    rm -rf $(VERTICA_UNPACKED); \
	    false; \
	  fi \
	else \
	  echo "Requires rpm2cpio (https://gist.github.com/dcode/798a9c69aa5076238a92 works)"; \
	  rm -rf $(VERTICA_UNPACKED); \
	  false; \
	fi \

else

VERTICA_INSTALL?=/opt/vertica
VERTICA_VERSION?=$(shell perl -nE 'my $$v=$$1 if m/Version\s*=\s*"(v[\d\.]*)-/; END { say $$v||"latest" }' $(VERTICA_INSTALL)/sdk/BuildInfo.java 2>/dev/null || echo "latest")

endif

TAGS=$(patsubst %,-t vertica/kafka-scheduler:%,$(VERTICA_VERSION))
SHELL:=/bin/bash

.PHONY: build
version: ## display the Vertica version to use (override with VERTICA_VERSION)
	@echo $(PACKAGE)
	@echo $(VERTICA_INSTALL)
	@echo $(VERTICA_VERSION)

.PHONY: build
build: $(VERTICA_INSTALL) ## build the docker image
	rm -rf java kafka
	cp -r $(VERTICA_INSTALL)/java java
	cp -r $(VERTICA_INSTALL)/packages/kafka kafka
	docker build . -t vertica/kafka-scheduler:$(word 1,$(VERTICA_VERSION))
	rm -rf java kafka

.PHONY: push
push: $(VERTICA_INSTALL) ## push the docker image up to docker hub
	rm -rf java kafka
	cp -r $(VERTICA_INSTALL)/java java
	cp -r $(VERTICA_INSTALL)/packages/kafka kafka
	#docker context create mycontext
	docker buildx rm vkconfig_builder >/dev/null 2>&1 || true
	docker buildx create --use --driver docker-container --name vkconfig_builder
	docker buildx inspect --bootstrap
	docker buildx build --platform=linux/arm64,linux/amd64 $(TAGS) . --push
	docker buildx rm vkconfig_builder >/dev/null 2>&1 || true
	rm -rf java kafka

.PHONY: test
test: ## suite of tests to make sure everything is working
	VERTICA_VERSION=$(word 1,$(VERTICA_VERSION)) ./example.sh

.PHONY: clean
clean: ## clean up local directory and docker image created by "make build"
	docker image rm vertica/kafka-scheduler:$(word 1,$(VERTICA_VERSION))
