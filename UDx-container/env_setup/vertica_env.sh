#!/usr/bin/env bash

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

#######################################################################################
# Set correct search PATH
export PATH="$PATH:${VERTICA_OPT_BIN}"

# admintools GUI, which works with /usr/bin/dialog
# is not happy with the default value for TERM on Ubuntu
# (the one on CentOS --- xterm --- is fine)
if grep -is centos /etc/os-release > /dev/null ; then
    # works better for Admintools on CentOS
    export TERM=xterm
elif grep -is ubuntu /etc/os-release > /dev/null ; then
    export TERM=linux
else
    export TERM=linux
fi

#######################################################################################
# Vertica variables and aliases
export VERTICA_DB_HOME="${VERTICA_DATA_DIR}/${VERTICA_DB_NAME}"
export VERTICA_CATALOG="${VERTICA_DB_HOME}/v_${VERTICA_DB_NAME}_*_catalog"
export VERTICA_DATA="${VERTICA_DB_HOME}/v_${VERTICA_DB_NAME}_*_data"
export VERTICA_DB_USER="`whoami`"

alias cdc="cd $VERTICA_CATALOG"
alias cdd="cd $VERTICA_DATA"

# Start / stop database (cluster)
#   be careful on multi-node cluster - it has to be executed under root using run_init
alias startdb="${VERTICA_OPT_BIN}/adminTools --tool start_db -d ${VERTICA_DB_NAME}"
alias stopdb="${VERTICA_OPT_BIN}/adminTools --tool stop_db -d ${VERTICA_DB_NAME}"

alias vsqlv="vsql -U ${VERTICA_DB_USER} -p 5433"

alias taillog="tail -f ${VERTICA_CATALOG}/vertica.log"
