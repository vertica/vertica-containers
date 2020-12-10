#+++++
#
# 	Description:
#	Builds the UDx build container
#	
#-----

CXX = g++
CONTAINER_TAG = verticasdk:latest

all: wrapper

# the RPM file has to be in this directory for the docker build process to find it 
VERTICA_RPM ?= vertica.rpm

docker-image: .dockerimage

.dockerimage: wrapper
	docker build \
		--build-arg RPM=$(VERTICA_RPM) \
		--tag $(CONTAINER_TAG) .
	touch .dockerimage

wrapper: wrapper.cpp
	$(CXX) wrapper.cpp -o wrapper

