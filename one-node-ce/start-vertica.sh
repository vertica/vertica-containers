#!/usr/bin/env bash

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

set -e

CID_TXT_DIR=`pwd`

IMAGE_NAME=vertica-ce
TAG=latest
CONTAINER_NAME=vertica_ce
DVOL=vertica-data 
VERTICA_PORT=5433

function usage_exit() {
    cat <<EOF
Usage: $0 [-c cname] [-d cid_dir] [-h] [-i img_name] [-t tag] [-v hostpath:containerdir] [-V docker-volume]
Options are:
 -c - specify container name (default is $CONTAINER_NAME)
 -d - directory-for-cid.txt (default is the current directory)
 -h - show help
 -i image - specify image name (default is $IMAGE_NAME)
 -p port - specify a port number to use for vsql to talk to vertica
 -t tag - specify the image tag (default is $TAG)
 -v hostpath:containerdir - mount hostpath as containerdir in the 
        container (in addition to the data docker volume)
 -V volume - docker volume to use for the Vertica database (default is $DVOL)
EOF
    exit $1
}

while getopts "c:d:hi:p:r:t:v:V:" opt; do
    case "$opt" in
        c) CONTAINER_NAME="${OPTARG}"
           ;;
        d) CID_TXT_DIR="${OPTARG}"
           ;;
        h) usage_exit 0
           ;;
        i) IMAGE_NAME=${OPTARG}
           ;;
        p) VERTICA_PORT=${OPTARG}
           ;;
        t) TAG="${OPTARG}"
           ;;
        v) VFLAG="-v ${OPTARG}"
           ;;
        V) DVOL="${OPTARG}"
           ;;
        \?) echo "Invalid option: -$OPTARG" >&2
            echo
            usage_exit 1
            ;;
    esac
done

AGENT_PORT=$(($VERTICA_PORT + 11))
CID_FILE=$CID_TXT_DIR/cid.txt

echo "Starting container..."
CID=`docker run -p $VERTICA_PORT:5433 -p $AGENT_PORT:5444 -d $VFLAG --mount type=volume,source=$DVOL,target=/data --name $CONTAINER_NAME $IMAGE_NAME:$TAG`
echo

echo "Container ID: $CID"
echo "Saving container ID to $CID_FILE"
echo $CID > $CID_FILE

echo
echo "Run"
echo "      docker logs $CID"
echo "or"
echo "      docker logs \`cat $CID_FILE\`"
echo "or"
echo "      docker logs $CONTAINER_NAME"
echo "to view startup progress"
echo
echo "Don't stop container until above command prints 'Vertica is now running'"
echo "To stop:"
echo "    docker stop $CID"
echo "or"
echo "    docker stop \`cat $CID_FILE\`"
echo "or"
echo "    docker stop $CONTAINER_NAME"
