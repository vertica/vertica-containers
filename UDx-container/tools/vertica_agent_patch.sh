#!/usr/bin/env bash

# Copyright (c) [2021-2023] Open Text.

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#    http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# v10 (and earlier, but v10 interested us enough to test in containers) 
# vertica_agent script uses the rpm command to find out where
# Vertica is installed.  But we threw the 900-1200 MB of rpm info away
# when we did the multi-stage build.  v11 and subsequent used a
# different technique more compatible with what we're doing with
# containers 
v_version=$(/opt/vertica/bin/vertica --version | awk '/Vertica Analytic Database/{ print $4 }')
case $v_version in 
v10*)
    mv /tmp/vertica_agent.11 /opt/vertica/sbin/vertica_agent
    chmod 775 /opt/vertica/sbin/vertica_agent
    ;;
esac
