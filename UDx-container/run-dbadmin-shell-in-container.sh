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

# Run a shell in the container

set -e

# UID of dbadmin inside the container
DBADMIN_ID=1000

usage_exit() {
    echo "Usage: $0 [-d directory-for-cid.txt] [-n container-name] [-u uid] [-h ] [ ? ]"
    exit 1
}

user_name=`id -un`
CONTAINER_NAME=verticasdk-${user_name}

while getopts "d:hn:u:" opt; do
    case "$opt" in
        h)
            usage_exit
            ;;
        n) 
            CONTAINER_NAME="${OPTARG}"
            ;;
        u)
            DBADMIN_ID="${OPTARG}"
            echo UID $DBADMIN_ID
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            echo
            usage_exit
            ;;
    esac
done

case "$DBADMIN_ID"x in
    x) echo "-u user required"
       usage_exit
       ;;
esac

# open bash in the container
docker exec -it --user $DBADMIN_ID $CONTAINER_NAME /bin/bash -l

