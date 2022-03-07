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
#	Builds the UDx build container
#
#       Copy the .rpm or .deb package to this directory and then invoke 
#		make TARGET=rpm
#	or
#		make TARGET=deb
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

ifeq ($(TARGET), rpm)
	PACKAGE ?= $(wildcard vertica*.rpm)
	CONTAINER_OS=centos
	CONTAINER_OS_VERSION ?= 7.9.2009
else ifeq ($(TARGET), deb)
	PACKAGE = $(wildcard vertica*.deb)
	CONTAINER_OS=ubuntu
	CONTAINER_OS_VERSION ?= 18.04
else
# can't indent because then it looks like part of a recipe
$(error "TARGET not set to 'rpm' or 'deb'")
endif

ifeq ($(PACKAGE), )
$(error "Cannot find the vertica install package in current working directory")
endif

# The user hasn't handed us a VERTICA_VERSION
ifeq ($(origin VERTICA_VERSION), undefined)
	version := $(shell python3 ./vertica_version_from_package.py -v $(PACKAGE))
	VERTICA_VERSION = $(version)
endif

CONTAINER_NAME = verticasdk
CONTAINER_TAG = $(CONTAINER_NAME):$(CONTAINER_OS)-$(VERTICA_VERSION)

DEFAULT:
	$(MAKE) vsdk-cp vsdk-g++ vsdk-make
ifeq ($(TARGET), rpm)	
	$(MAKE) rpm_build \
		PACKAGE=$(PACKAGE) \
		TARGET=$(TARGET) \
		VERTICA_VERSION=$(VERTICA_VERSION) \
		OS_VERSION=$(CONTAINER_OS_VERSION) \
		SUFFIX=${SUFFIX}
else ifeq ($(TARGET), deb)
	$(MAKE) deb_build \
		PACKAGE=$(PACKAGE) \
		TARGET=$(TARGET) \
		VERTICA_VERSION=$(VERTICA_VERSION) \
		OS_VERSION=$(CONTAINER_OS_VERSION) \
		SUFFIX=${SUFFIX}
else
	$(error "TARGET not set to 'rpm' or 'deb'")
endif

.PHONY: display
display: $(PACKAGE) 
	$(info Variable settings:)
	$(info PACKAGE: $(PACKAGE))
	$(info CONTAINER OS: $(CONTAINER_OS))
	$(info CONTAINER_NAME: $(CONTAINER_NAME))
	$(info VERTICA_VERSION: $(VERTICA_VERSION))
	$(info CONTAINER_TAG: $(CONTAINER_TAG))

.PHONY: rpm_build
# Defining ${SUFFIX} makes it easier to try variations on the Dockerfile_RPM
rpm_build: $(PACKAGE) display Dockerfile_RPM${SUFFIX}
	$(info VERTICA_RPM: $(PACKAGE))
	$(info CONTAINER_OS_VERSION: $(CONTAINER_OS_VERSION))
	docker build \
		-f Dockerfile_RPM${SUFFIX} \
		--build-arg RPM=$(PACKAGE) \
		--build-arg os_version=$(CONTAINER_OS_VERSION) \
		--build-arg vertica_version=$(VERTICA_VERSION) \
		--tag $(CONTAINER_TAG) .
	touch .rpm_dockerimage

# deb files are ar-archives containing tarfiles
# unlike cpio, tar does not take wildcards in the list of files
# to be extracted, so we have to do the translation from wild-card to
# concrete file list by hand
deb-file-extract-list: $(PACKAGE) file-patterns make-deb-file-extract-list
	sh ./make-deb-file-extract-list $(PACKAGE)

.PHONY: deb_build
# Defining ${SUFFIX} makes it easier to try variations on the Dockerfile_DEB
deb_build: $(PACKAGE) display deb-file-extract-list Dockerfile_DEB${SUFFIX}
	$(info VERTICA_DEB: $(PACKAGE))
	$(info CONTAINER_OS_VERSION: $(CONTAINER_OS_VERSION))
	docker build \
		-f Dockerfile_DEB${SUFFIX} \
		--build-arg DEB=$(PACKAGE) \
		--build-arg os_version=$(CONTAINER_OS_VERSION) \
		--build-arg vertica_version=$(VERTICA_VERSION) \
		--tag $(CONTAINER_TAG) .
	touch .deb_dockerimage

vsdk-cp vsdk-g++ vsdk-make: vsdk-bash
	rm -f $@ ; ln vsdk-bash $@

.PHONY: commands
commands: vsdk-cp vsdk-g++ vsdk-make

# we'll need the pathname of this working directory when
# testing with vsdk-make
THIS_DIR := $(realpath .)

.PHONY: test
test: commands
	rm -rf tmp-test
	mkdir tmp-test
	VERTICA_VERSION=$(VERTICA_VERSION) \
		./vsdk-cp -r /opt/vertica/sdk/examples tmp-test
	cd tmp-test/examples && \
		VERTICA_VERSION=$(VERTICA_VERSION) \
		$(THIS_DIR)/vsdk-make \
			ScalarFunctions \
			TransformFunctions \
			AnalyticFunctions \
			AggregateFunctions \
			UserDefinedLoad
