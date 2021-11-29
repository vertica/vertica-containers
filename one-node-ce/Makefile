# (c) Copyright [2021] Micro Focus or one of its affiliates.
# Licensed under the Apache License, Version 2.0 (the "License");
# You may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Image tag to the image. To use something other than the default, run:
#
# "make TAG=your-choice",
# e.g., 
# "make TAG=11.0.1-1"
#
# If you don't specify a VERTICA_PACKAGE, and the TAG is not
# 'latest' then the TAG is expected to be the vertica version and used
# to construct the VERTICA_PACKAGE name
TAG ?= latest

# Image name to the image. To change the default, run: make IMAGE_NAME=vertica
IMAGE_NAME ?= vertica-ce

# Optional properties to define for DB user in the container.
# Defaults:
#   VERTICA_DB_UID:1000
#   VERTICA_DB_USER:dbadmin
#   VERTICA_DB_GROUP:verticadba
#   VERTICA_DB_NAME:VMart
# (These defaults are set up in the Dockerfiles, we pass in override commands
# if the following are non-null.)
# To change the defaults, run: make VERTICA_DB_UID=1200
VERTICA_DB_UID ?= 
VERTICA_DB_USER ?=
VERTICA_DB_GROUP ?= 
VERTICA_DB_NAME ?= 

ifeq ($(origin OS_TYPE), undefined)
	ifneq ($(origin VERTICA_PACKAGE), undefined)
		ifeq (.deb, $(findstring .deb, $(VERTICA_PACKAGE)))
			OS_TYPE=Ubuntu
		else
			OS_TYPE=CentOS
		endif
	else
# can't indent because then it looks like part of a recipe
$(error "Need one of OS_TYPE or VERTICA_PACKAGE to be defined")
	endif
endif


# This step ensures that the script builds CentOS7.9.2009 in default.
# Check for Image OS and assign default values to OS_VERSION, if not defined.
ifeq ($(OS_TYPE),Ubuntu)
	OS_VERSION ?= 18.04
	ifeq ($(TAG),latest)
		VERTICA_PACKAGE ?= vertica.latest.deb
	else
		VERTICA_PACKAGE ?= vertica_$(TAG)_amd64.deb
	endif
	ifeq (.rpm, $(findstring .rpm, $(VERTICA_PACKAGE)))
$(error "Choice of OS_TYPE Ubuntu not consistent with choice of .rpm file for VERTICA_PACKAGE")
	endif
else
	OS_TYPE = CentOS 
	OS_VERSION ?= 7.9.2009
	ifeq ($(TAG),latest)
		VERTICA_PACKAGE ?= vertica-x86_64.RHEL6.latest.rpm
	else
		VERTICA_PACKAGE ?= vertica-$(TAG).x86_64.RHEL6.rpm
	endif
	ifeq (.deb, $(findstring .deb, $(VERTICA_PACKAGE)))
$(error "Choice of OS_TYPE CentOS not consistent with choice of .deb file for VERTICA_PACKAGE")
	endif
endif

# Default VERTICA_IMAGE=vertica-ce:latest. To change, run: make IMAGE_NAME=vertica TAG=latest
VERTICA_IMAGE=${IMAGE_NAME}:${TAG}

ifneq ($(VERTICA_DB_UID),)
	UID_ARG=--build-arg dbadmin_id=${VERTICA_DB_UID}
endif

ifneq ($(VERTICA_DB_USER),)
	USER_ARG=--build-arg vertica_db_user=${VERTICA_DB_USER}
endif

ifneq ($(VERTICA_DB_GROUP),)
	GROUP_ARG=--build-arg vertica_db_group=${VERTICA_DB_GROUP}
endif

ifneq ($(VERTICA_DB_NAME),)
	UID_ARG=--build-arg vertica_db_name=${VERTICA_DB_NAME}
endif


all: docker-build

.PHONY: display
display:
	$(info  Defined Parameters)
	$(info    - Image Name  ='$(IMAGE_NAME)', Default:vertica-ce)
	$(info    - Tag         ='$(TAG)', Default:latest)
	$(info    - OS Type     ='$(OS_TYPE)', Default:CentOS)
	$(info    - OS Version  ='$(OS_VERSION)', Default:7.9.2009)
	$(info    - DB User     ='$(VERTICA_DB_USER)', Default if blank: dbadmin)
	$(info    - DB Group    ='$(VERTICA_DB_GROUP)', Default if blank: verticadba)
	$(info    - DB Name     ='$(VERTICA_DB_NAME)', Default if blank: :VMart)
	$(info    - DB UID      ='$(VERTICA_DB_UID)', Default if blank: 1000)



.PHONY: docker-build
docker-build: packages/${VERTICA_PACKAGE} display Dockerfile_$(OS_TYPE)
	docker build \
	   -f Dockerfile_${OS_TYPE} \
	   --build-arg os_version=${OS_VERSION} \
	   --build-arg vertica_package=${VERTICA_PACKAGE} \
	   ${GROUP_ARG} \
	   ${NAME_ARG} \
	   ${UID_ARG} \
	   ${USER_ARG} \
	   -t ${VERTICA_IMAGE} .

.PHONY: test
test: run-tests.sh 
	./run-tests.sh
