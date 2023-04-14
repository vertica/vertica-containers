#
# Copyright (c) [2021-2023] OpenText.

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#    http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#+++++
#
# 	Description:
#	Builds the UDx build container
#
#       Copy the .rpm or .deb package to this directory and then invoke
#		make TARGET=rpm build
#	or
#		make TARGET=deb build
#       whichever applies to your package
#
# This makefile tries to extract the Version and OS from the way
# Vertica names rpm and deb files for release.  If you don't have a
# file with a canonical name (like these):
#
#       vertica-10.1.1-5.x86_64.RHEL6.rpm
#       vertica-10.1.1-5.x86_64.SUSE.rpm
#       vertica-11.0.0-20210723.x86_64.RHEL6.rpm
#       vertica_10.1.1-5_amd64.deb
#       vertica_11.0.0-20210723_amd64.deb
#
# (but have, say, something like this):
#
#	vertica.rpm
#	vertica.deb
#       vertica-x86_64.RHEL6.latest.rpm
#       vertica.latest.deb
#
# Then you'll need to specify VERTICA_VERSION as well as TARGET.
# If you have more than one rpm or deb file, in this directory, you'll
# need to specify the filename in the PACKAGE variable

# CONTAINER_OS specifies the OS used to build the container --- it is
#	only used to generate the image tag
# CONTAINER_OS_VERSION is passed into the Dockerfile (mostly for those
#	who wish to use CentOS8)
# PACKAGE specifies the name of the RPM or DEB file
# TARGET is one of {deb, rpm} specifying the kind of package one is
#	building from
# VERTICA_VERSION will be used for the image tag, and is extracted
#	from the PACKAGE filename, if it is available there
#
# Docker Hub
#
# These images are also available on docker hub by Vertica's release
# engineering team using these steps:
# 1) download the debian and redhat packages
# 2) login into docker with "docker login"
# 3) for i in *.+(deb|rpm); do make PACKAGE=$i build push; done

help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' "$(firstword $(MAKEFILE_LIST))"

ifeq ($(TARGET), rpm)
  PACKAGE ?= $(wildcard vertica*.rpm)
else ifeq ($(TARGET), deb)
  PACKAGE = $(wildcard vertica*.deb)
else
  # find the package if not specified
  PACKAGE ?= $(wildcard vertica*.rpm vertica*.deb)
endif

# make sure there is just 1
ifneq ($(words $(PACKAGE)),1)
  PACKAGE = "PACKAGE - Use 'make PACKAGE=verticaXXX.xxx'"
else
  # extract target from package
  TARGET := $(patsubst %.deb,deb,$(patsubst %.rpm,rpm,$(PACKAGE)))
endif

ifeq ($(TARGET), rpm)
  TARGET_U=RPM
  CONTAINER_OS=centos
  CONTAINER_OS_VERSION ?= 7.9.2009
else ifeq ($(TARGET), deb)
  TARGET_U=DEB
  CONTAINER_OS=ubuntu
  CONTAINER_OS_VERSION ?= 18.04
endif

# The user hasn't handed us a VERTICA_VERSION
ifeq ($(origin VERTICA_VERSION), undefined)
	version := $(firstword $(subst -, ,$(patsubst vertica_%,%,$(patsubst vertica-%,%,$(basename $(PACKAGE))))))
	# use this if you want the hotfix number in the CONTAINER_TAG
	#version := $(subst _amd64.deb,,$(subst .x86_64.RHEL6.rpm,,$(patsubst vertica_%,%,$(patsubst vertica-%,%,$(PACKAGE)))))

	VERTICA_VERSION = $(version)
endif

CONTAINER_NAME = vertica/verticasdk
export CONTAINER_TAG = $(CONTAINER_NAME):$(CONTAINER_OS)-v$(VERTICA_VERSION)

build: display Dockerfile_$(TARGET_U) ${SUFFIX} ## Build container given PACKAGE=<file>
	# link/copy rpm file to local directory and clean it up when done
	@ln $(PACKAGE) vertica.$$$$.rpm 2>/dev/null || cp $(VERTICA_RPM) vertica.$$$$.rpm || exit 1 \
	trap "rm -f vertica.$$$$.rpm" EXIT INT; \
	docker build \
		-f Dockerfile_$(TARGET_U)${SUFFIX} \
		--build-arg $(TARGET_U)=vertica.$$$$.rpm \
		--build-arg os_version=$(CONTAINER_OS_VERSION) \
		--build-arg vertica_version=$(VERTICA_VERSION) \
		--tag $(CONTAINER_TAG) .

.PHONY: display
display: ## Display internal Makefile variables
	$(info Variable settings:)
	$(info PACKAGE: $(PACKAGE))
	$(info CONTAINER OS: $(CONTAINER_OS))
	$(info CONTAINER_NAME: $(CONTAINER_NAME))
	$(info VERTICA_VERSION: $(VERTICA_VERSION))
	$(info CONTAINER_TAG: $(CONTAINER_TAG))
	@:

# we'll need the pathname of this working directory when
# testing with vsdk-make
THIS_DIR := $(realpath .)

.PHONY: test
test:
	rm -rf tmp-test
	mkdir tmp-test
	# test vsdk-cp to copy examples from container to local dir
	./vsdk-cp -r /opt/vertica/sdk/examples tmp-test
	# test building stuff in local dir
	cd tmp-test/examples && \
		$(THIS_DIR)/vsdk-make \
			ScalarFunctions \
			TransformFunctions \
			AnalyticFunctions \
			AggregateFunctions \
			UserDefinedLoad
	# do objects exist?
	ls -l tmp-test/examples/build/ScalarFunctions.so
	ls -l tmp-test/examples/build/TransformFunctions.so
	ls -l tmp-test/examples/build/AnalyticFunctions.so
	ls -l tmp-test/examples/build/AggregateFunctions.so
	ls -l tmp-test/examples/build/IconverterLib.so
	# clean up
	rm -rf tmp-test
	# test vsdk-bash and verify path is valid
	./vsdk-bash -c 'IFS=:; for i in $$PATH; do ls -ld $$i >/dev/null || exit 1; done'

.PHONY:push
push: ## push built container up to docker hub
	docker push $(CONTAINER_TAG)
