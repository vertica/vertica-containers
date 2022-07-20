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

CONTAINER_OS=ubuntu
CONTAINER_OS_VERSION ?= 20.04
CONTAINER_NAME = wasm-playground
CONTAINER_TAG = $(CONTAINER_NAME):$(CONTAINER_OS)
# defineing SUFFIX makes it easier to try variations on the Dockerfile
# SUFFIX=${SUFFIX}

DEFAULT:
	$(MAKE) deb_build \
		OS_VERSION=$(CONTAINER_OS_VERSION) 

.PHONY: display
display: 
	$(info Variable settings:)
	$(info CONTAINER OS: $(CONTAINER_OS))
	$(info CONTAINER_NAME: $(CONTAINER_NAME))
	$(info CONTAINER_TAG: $(CONTAINER_TAG))

.PHONY: deb_build
# Defining ${SUFFIX} makes it easier to try variations on the Dockerfile
deb_build: display Dockerfile${SUFFIX} get-wasmer get-rustup
	$(info CONTAINER_OS_VERSION: $(CONTAINER_OS_VERSION))
	docker build \
		-f Dockerfile${SUFFIX} \
		--build-arg os_version=$(CONTAINER_OS_VERSION) \
		--tag $(CONTAINER_TAG) .
	touch .deb_dockerimage

