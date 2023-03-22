#
# Copyright (c) [2021] Micro Focus or one of its affiliates.

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
#
#	Builds the UDx build container using a Vertica ubuntu .deb
#	distribution file (while the standard UDx container can be
#	built for both CentOS and Ubuntu, we just found it easier to
#	add the wasmer tools to Ubuntu.
#
#       Copy the .deb package to this directory and then invoke 
#		make 
#
# This makefile tries to extract the Version and OS from the way
# Vertica names deb files for release.  If you don't have a
# file with a canonical name (like these):
#
#       vertica_10.1.1-5_amd64.deb
#       vertica_11.0.0-20210723_amd64.deb
#
# (but have, say, something like this): 
#
#	vertica.deb
#       vertica.latest.deb
#
# Then you'll need to specify VERTICA_VERSION.
# If you have more than one deb file in this directory, you'll
# need to specify the filename in the PACKAGE variable

# CONTAINER_OS specifies the OS used to build the container --- it is
#	only used to generate the image tag
# CONTAINER_OS_VERSION is passed into the Dockerfile
# PACKAGE specifies the name of the RPM or DEB file
# VERTICA_VERSION will be used for the image tag, and is extracted
#	from the PACKAGE filename, if it is available there

TARGET=deb
ifndef PACKAGE
	PACKAGE := $(wildcard vertica*.deb)
else ifndef VERTICA_VERSION
$(error Please define VERTICA_VERSION)
endif
CONTAINER_OS=ubuntu
CONTAINER_OS_VERSION ?= 20.04

# The user hasn't handed us a VERTICA_VERSION
ifeq ($(origin VERTICA_VERSION), undefined)
	version := $(shell python3 ./vertica_version_from_package.py -v $(PACKAGE))
	VERTICA_VERSION = $(version)
endif

CONTAINER_NAME = vwasmsdk
CONTAINER_TAG = $(CONTAINER_NAME):$(CONTAINER_OS)-$(VERTICA_VERSION)

DEFAULT:
	$(MAKE) deb_build \
		PACKAGE=$(PACKAGE) \
		TARGET=$(TARGET) \
		VERTICA_VERSION=$(VERTICA_VERSION) \
		OS_VERSION=$(CONTAINER_OS_VERSION) \
		SUFFIX=${SUFFIX}

.PHONY: display
display: 
	$(info Variable settings:)
	$(info PACKAGE: $(PACKAGE))
	$(info CONTAINER OS: $(CONTAINER_OS))
	$(info CONTAINER_NAME: $(CONTAINER_NAME))
	$(info VERTICA_VERSION: $(VERTICA_VERSION))
	$(info CONTAINER_TAG: $(CONTAINER_TAG))

# deb files are ar-archives containing tarfiles
# unlike cpio, tar does not take wildcards in the list of files
# to be extracted, so we have to do the translation from wild-card to
# concrete file list by hand
deb-file-extract-list: $(PACKAGE) file-patterns make-deb-file-extract-list
	sh ./make-deb-file-extract-list $(PACKAGE)

.PHONY: deb_build
# Defining ${SUFFIX} makes it easier to try variations on the Dockerfile
deb_build: display deb-file-extract-list Dockerfile${SUFFIX}
	$(info VERTICA_DEB: $(PACKAGE))
	$(info CONTAINER_OS_VERSION: $(CONTAINER_OS_VERSION))
	docker build \
		-f Dockerfile${SUFFIX} \
		--build-arg DEB=$(PACKAGE) \
		--build-arg os_version=$(CONTAINER_OS_VERSION) \
		--build-arg vertica_version=$(VERTICA_VERSION) \
		--tag $(CONTAINER_TAG) .
	touch .deb_dockerimage

