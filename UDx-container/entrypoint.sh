#!/bin/bash

# -*- mode: shell-script -*-
# (c) Copyright [2021-2023] Open Text.
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

# secret debug option
if [[ -n $VERTICA_DEBUG_ENTRYPOINT ]] ; then
  set -x
fi

#
# The default is to enter the container as dbadmin, so if they are specifying
# -u, don't do anything special
#
vsdk_cmd="$1"
if [[ $(id -un 2>/dev/null) != dbadmin || $vsdk_cmd != vertica ]]; then
  exec "$@"
fi

source /etc/profile

VSQL=/opt/vertica/bin/vsql

ADMINTOOLS="${VERTICA_OPT_DIR}/bin/admintools"
: ${VERTICA_OPT_DIR:="/opt/vertica"}
: ${VERTICA_VOLUME_DIR:="/data"}
: ${VERTICA_DATA_DIR:="${VERTICA_VOLUME_DIR}/vertica"}
: ${VERTICA_DB_NAME:="vsdk"}

# Vertica should be shut down properly
function shut_down() {
    echo "Shutting Down"
    vertica_proper_shutdown
    echo 'Stopping loop'
    STOP_LOOP="true"
}

function vertica_proper_shutdown() {
    db=$(${ADMINTOOLS} -t show_active_db)
    case "$db" in
        ("")
            echo "Database not running --- shutting down"
            ;;
        (*)
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
    if ! [[ -f ${VERTICA_DATA_DIR}/config/admintools.conf ]]; then
        # first time through docker-entrypoint.sh we need to move
        # the config directory to persistent store
        /bin/sudo cp --archive ${VERTICA_OPT_DIR}/config ${VERTICA_DATA_DIR}
        /bin/sudo chown -R ${VERTICA_DB_USER} ${VERTICA_DATA_DIR}/config
    fi
    # unfortunately, the symlink is in the container image
    # so we have to renew it each time if a shared volume is used for $VERTICA_VOLUME_DIR
    if [ ! -L ${VERTICA_OPT_DIR}/config ]; then
        echo "symlink ${VERTICA_OPT_DIR}/config -> ${VERTICA_DATA_DIR}/config"
        sudo rm -rf ${VERTICA_OPT_DIR}/config
        sudo ln -snf  ${VERTICA_DATA_DIR}/config  ${VERTICA_OPT_DIR}/config
    fi
}

function initialize_vertica_directories() {
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
}

function start_vertica() {
    # ${VERTICA_OPT_DIR}/config/admintools.conf is the unmodified container
    # copy, but we symlinked it the first time through, and have to
    # recreate that symlink
    preserve_config
    echo 'Starting Database'
    if ${ADMINTOOLS} -t start_db \
                  --database=$VERTICA_DB_NAME \
                  --noprompts; then
        echo "Vertica is now running"
    else
        echo "Admintools was unable to start Vertica"
    fi
}

# A container that runs Vertica hangs around until Vertica exits ---
# it exists to provide a Vertica server to interact with.
#
# A container that runs commands like cp, bash, gcc, make, etc., is
# used to provide an environment for those commands to execute in.
# When the command completes, the container goes away.
STOP_LOOP=false
trap "shut_down" SIGKILL SIGTERM SIGHUP SIGINT

if [ ! -d ${VERTICA_DATA_DIR}/${VERTICA_DB_NAME} ]; then
  initialize_vertica_directories
else
  start_vertica
fi

while [ "${STOP_LOOP}" == "false" ]; do
    # We could use admintools -t show_active_db to see if the
    # db is still running, and restart it if it isn't
    sleep 10
done
