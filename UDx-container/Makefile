#+++++
#
# 	Description:
#	Builds the UDx build container
#	
#-----

CXX = g++
CONTAINER_TAG ?= verticasdk:latest

all: docker-image

# the RPM file has to be in this directory for the docker build process to find it 
VERTICA_RPM ?= vertica.rpm

docker-image: .dockerimage

.dockerimage: $(VERTICA_RPM) Makefile Dockerfile
        # link/copy rpm file to local directory and clean it up when done
	ln $(VERTICA_RPM) vertica.$$$$.rpm || cp $(VERTICA_RPM) vertica.$$$$.rpm ; \
	trap "rm -f vertica.$$$$.rpm" EXIT INT; \
	docker build \
		--build-arg RPM=vertica.$$$$.rpm \
		--tag $(CONTAINER_TAG) .
	touch .dockerimage
