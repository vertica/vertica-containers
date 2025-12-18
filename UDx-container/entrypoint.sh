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

# entrypoint script for UDx development container

# The container is meant to be invoked by the vsdk-* family of
# commands, which mount many of the user's directories and prepare a
# command such as bash, make, or g++ to be executed inside this
# container.

# secret debug option
if [[ -n $VERTICA_DEBUG_ENTRYPOINT ]] ; then
  set -x
fi

vsdk_dir="$1"
vsdk_cmd="$2"

# Execute the development command in the specified directory
cd "$vsdk_dir"
sh -c "$vsdk_cmd"
