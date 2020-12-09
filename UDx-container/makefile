#+++++
#
# 	Description:
#	Builds the UDx build container
#	
#-----

CXX = g++
CONTAINER_TAG = verticasdk:0.1b

all: docker-image-build wrapper

# the RPM file has to be in this directory for the docker build process to find it 
VERTICA_RPM ?= vertica.rpm

docker-image-build: .dockerimage

.dockerimage: wrapper
	docker build \
		--build-arg rpm=vertica.rpm \
		--tag $(CONTAINER_TAG) .
	touch $(BUILD_CONTAINER_DIR)/.dockerimage

wrapper: wrapper.cpp
	$(CXX) wrapper.cpp -o wrapper

