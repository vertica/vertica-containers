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

CONTAINER_NAME=vertica_ce_$$
VOLUME_NAME=vertica-test-$$
IMAGE_NAME=vertica-ce
TAG=latest
# "global variable"
ERROR_COUNT=0
KEEP_CONTAINER=discard

# so we can run even if there's a running container
VERTICA_PORT=$(( ( $RANDOM % 64000 ) + 1024))

# translate "true" and "false" into exit status
TRUE_EXIT=0
FALSE_EXIT=1

# called with exit status
function usage_exit() {
    cat <<EOF
Usage: $0 [-c cname] [-h] [-i image] [-k] [-t tag] 
Options are:
 -c container - specify container name (default is $CONTAINER_NAME)
 -h - show help
 -i image - specify image name (default is $IMAGE_NAME)
 -k - keep the container (so you can attach to it and debug it)
 -t tag - specify the image tag (default is $TAG)

EOF
    exit $1
}

while getopts "c:hi:kt:" opt; do
    case "$opt" in
        c) CONTAINER_NAME="${OPTARG}"
           ;;
        h) usage_exit $TRUE_EXIT
           ;;
        i) IMAGE_NAME=${OPTARG}
           ;;
        k) KEEP_CONTAINER=retain 
           ;;
        t) TAG="${OPTARG}"
           ;;
        \?) echo "Invalid option: -$OPTARG" >&2
            echo
            usage_exit $FALSE_EXIT
            ;;
    esac
done

# syntax is so ugly let's bury it in a fn
function inc_ERROR_COUNT() {
    ERROR_COUNT=$(($ERROR_COUNT+1))
}

# called with ${CONTAINER_NAME}
function wait_for_container_to_start() {
    echo Waiting for $1 to start....
    while true; do
        if ( docker logs $1 2>1 | grep -s "Vertica is now running" ) > /dev/null ; then
            echo -n 'running at '; date
            return
        fi
        echo -n 'not running yet '; date
        sleep 5
    done
}

function canary() {
    if vsql -p $VERTICA_PORT -U dbadmin -A -t -c 'select 1' > /dev/null; then
        return $TRUE_EXIT
    else
        inc_ERROR_COUNT
        return $FALSE_EXIT
    fi
}

function flextable_library_loaded() {
    # verify that (at least one of) the optional libraries got loaded
    if [ `vsql  -p $VERTICA_PORT -U dbadmin -f tests/flex_table_loaded.sql -t` == t ]; then
        echo Container vertica loaded the flextable library successfully
        return $TRUE_EXIT
    else
        cat <<EOF
$0: ERROR: container vertica did not succeed in loading the 
flextable 
EOF
        inc_ERROR_COUNT
        return $FALSE_EXIT
    fi
}

# Called with table name suffix
function load_table() {
    (vsql  -p $VERTICA_PORT -U dbadmin -q -t <<EOF
drop table if exists t_$1;
create table t_$1 (a int, b int) ;
insert into t_$1 (a, b) values (3, 1);
insert into t_$1 (a, b) values (4, 1);
insert into t_$1 (a, b) values (5, 9);
insert into t_$1 (a, b) values (2, 6);
insert into t_$1 (a, b) values (5, 3);
insert into t_$1 (a, b) values (5, 9);
commit
EOF
    ) 2>&1 > /dev/null
}

# Called with table name suffix
function table_is_still_there() {
    if [ `vsql  -p $VERTICA_PORT -U dbadmin -t -c "select count(*) from t_$1"` == 6 ]; then
        echo Table t_$1 is loaded into Vertica
        return $TRUE_EXIT
    else
        echo ERROR: table t_$1 is not present in Vertica
        inc_ERROR_COUNT
        return $FALSE_EXIT
    fi
}

function load_and_verify_table() {
    load_table $$
    table_is_still_there $$
}

# takes an argument:
# If the argument is "internal", we're stopping and removing the
# container with the intent of restarting it --- retain the volume.
# If the argument is "terminal", we're stopping the container
# at the end of the test --- clean up the volume as well
function stop_and_remove_container() {
  (
    docker stop ${CONTAINER_NAME}
    docker rm ${CONTAINER_NAME}
    if [[ $1 == terminal ]]; then
        docker volume rm ${VOLUME_NAME}
    fi
  ) > /dev/null
}

function start_container() {
    # verify that the Vertica server is up and runnign
    if ./start-vertica.sh -c ${CONTAINER_NAME} -i ${IMAGE_NAME} -p ${VERTICA_PORT} -t ${TAG} -V ${VOLUME_NAME} ; then
        wait_for_container_to_start ${CONTAINER_NAME}
        return $TRUE_EXIT
    else
        # hopefully start-vertica printed a useful error message
        cat <<EOF
$0: ERROR: Cannot start-vertica -c ${CONTAINER_NAME} -i ${IMAGE_NAME} -p ${VERTICA_PORT} -t ${TAG} -V ${VOLUMEN_NAME}
EOF
        inc_ERROR_COUNT
        return $FALSE_EXIT
    fi  
}

function verify_basic_query() {
    if canary; then
        echo can connect to database and run basic query
        return $TRUE_EXIT
    else
        echo ERROR: cannot connect to database and run basic query
        inc_ERROR_COUNT
        return $FALSE_EXIT
    fi
}    

function some_admintools_tests() {
    DBNAME=$(docker exec --user dbadmin ${CONTAINER_NAME} \
                    /opt/vertica/bin/admintools -t show_active_db)
    if [[ $? == 0 ]]; then
        if docker exec --user dbadmin ${CONTAINER_NAME} \
               /opt/vertica/bin/admintools -t return_epoch -d ${DBNAME}; then
            echo admintools can talk to the database in the container
            return $TRUE_EXIT
        fi
    fi
    echo ERROR: admintools cannot talk to the database in the container
    inc_ERROR_COUNT
    return $FALSE_EXIT
}

function run_tests() {
    if ( which vsql 2>/dev/null 1>/dev/null) ; then
        ERROR_COUNT=0
    else
        cat <<EOF
ERROR: cannot find vsql in PATH
please edit your PATH to include the directory with vsql         
EOF
        exit 1
    fi
    start_container
    [ $ERROR_COUNT == 0 ] && verify_basic_query
    # verify that we can load a table
    [ $ERROR_COUNT == 0 ] && flextable_library_loaded
    [ $ERROR_COUNT == 0 ] && load_and_verify_table
    # and verify that the table survives a container shutdown and restart 
    [ $ERROR_COUNT == 0 ] && stop_and_remove_container internal
    [ $ERROR_COUNT == 0 ] && start_container
    [ $ERROR_COUNT == 0 ] && load_and_verify_table
    [ $ERROR_COUNT == 0 ] && some_admintools_tests

    if [[ $ERROR_COUNT != 0 ]]; then
        cat <<EOF
ERROR: $ERROR_COUNT tests failed.        
EOF
    else
        echo "All tests passed"
    fi
    if [[ ${KEEP_CONTAINER} == retain ]]; then
        echo Retaining the container and its volume 
        echo When done with them, run:
        echo "    docker stop ${CONTAINER_NAME}"
        echo "    docker rm ${CONTAINER_NAME}"
        echo "    docker volume rm ${VOLUME_NAME}"
    else 
        stop_and_remove_container terminal
    fi

}

run_tests
exit $ERROR_COUNT
