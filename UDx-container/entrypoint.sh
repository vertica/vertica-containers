#!/bin/bash

# -*- mode: shell-script -*-
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

# entrypoint script for UDx container

# The container is meant to be invoked by the vsdk-* family of
# commands, which mount many of the user's directories and prepare a
# command such as bash, make, or g++ to be executed inside this
# container. 

VSQL=/opt/vertica/bin/vsql
vsdk_dir="$1"
vsdk_cmd="$2"

ADMINTOOLS="${VERTICA_OPT_DIR}/bin/admintools"

# Vertica should be shut down properly
function shut_down() {
    echo "Shutting Down"
    vertica_proper_shutdown
    echo 'Stopping loop'
    STOP_LOOP="true"
}

function vertica_proper_shutdown() {
    db=$(${ADMINTOOLS} -t show_active_db)
    case "$db"x in
        x) 
            echo "Database not running --- shutting down"
            ;;
        *)
            echo 'Vertica: Closing active sessions'
            ${VSQL} -c 'SELECT CLOSE_ALL_SESSIONS();'
            echo 'Vertica: Flushing everything on disk'
            ${VSQL} -c 'SELECT MAKE_AHM_NOW();'
            echo 'Vertica: Stopping database'
            ${ADMINTOOLS} -t stop_db -d $VERTICA_DB_NAME -i
            ;;
    esac
}

function preserve_config() {
    # unfortunately, admintools doesn't (always) obey symlinks when
    # manipulating its admintools.conf file, so we have to move the
    # entire config directory  
    if [ -f ${VERTICA_DATA_DIR}/config/admintools.conf ]; then
        # second and subsequent times starting the container
        # we have an admintools.conf in ${VERTICA_DATA_DIR}
        echo "config has already been preserved"
    else
        # first time through docker-entrypoint.sh we need to move
        # the config directory to persistent store
        echo "Moving config directory tree to persistent store"
        sudo cp --archive ${VERTICA_OPT_DIR}/config ${VERTICA_DATA_DIR}
        sudo chown -R ${VERTICA_DB_USER} ${VERTICA_DATA_DIR}/config
    fi
    # unfortunately, the symlink is in the container image
    # so we have to renew it each time
    if [ ! -L ${VERTICA_OPT_DIR}/config ]; then
        echo "symlink ${VERTICA_OPT_DIR}/config -> ${VERTICA_DATA_DIR}/config"
        rm -rf ${VERTICA_OPT_DIR}/config
        ln -s  ${VERTICA_DATA_DIR}/config  ${VERTICA_OPT_DIR}/config
    fi
}       

function initialize_vertica_directories() {
    # We only do this if necessary
    if [ ! -d ${VERTICA_DATA_DIR}/${VERTICA_DB_NAME} ]; then
        # first time through --- create db, etc.
        mkdir -p ${VERTICA_DATA_DIR}/config
        preserve_config
        echo 'Creating database'

        ${ADMINTOOLS} -t create_db \
                      --skip-fs-checks \
                      -s localhost \
                      --database=$VERTICA_DB_NAME \
                      --catalog_path=${VERTICA_DATA_DIR} \
                      --data_path=${VERTICA_DATA_DIR}

        echo
        if [ -n "${APP_DB_USER}" ]; then
            create_app_db_user
        fi
    fi
}

function start_vertica() {
    # ${VERTICA_OPT_DIR}/config/admintools.conf is the unmodified container
    # copy, but we symlinked it the first time through, and have to
    # recreate that symlink
    preserve_config
    echo 'Starting Database'
    ${ADMINTOOLS} -t start_db \
                  --database=$VERTICA_DB_NAME \
                  --noprompts

}

# A container that runs Vertica hangs around until Vertica exits ---
# it exists to provide a Vertica server to interact with.
#
# A container that runs commands like cp, bash, gcc, make, etc., is
# used to provide an environment for those commands to execute in.
# When the command completes, the container goes away.
case $vsdk_cmd in
    vertica*)
        STOP_LOOP=false
        trap "shut_down" SIGKILL SIGTERM SIGHUP SIGINT
        initialize_vertica_directories
        start_vertica
        echo "Vertica is now running"
        
        while [ "${STOP_LOOP}" == "false" ]; do
            # We could use admintools -t show_active_db to see if the
            # db is still running, and restart it if it isn't
            sleep 10
        done
        ;;
    *)
        cd "$vsdk_dir"
        sh -c "$vsdk_cmd"
        ;;
esac
