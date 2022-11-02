#!/bin/bash
# © Copyright 2022 Micro Focus or one of its affiliates
#
# This script file wraps a containerized vkconfig.
# Requires readlink but tries to make due without.

: ${VERTICA_VERSION:=$(perl -nE 'my $v=$1 if m/Version\s*=\s*"v([\d\.]*)-/; END { say $v||"latest" }' /opt/vertica/sdk/BuildInfo.java 2>/dev/null || echo "latest")}

if ! SCRIPT_DIR=$(readlink -f ${BASH_SOURCE[0]} 2>/dev/null); then SCRIPT_DIR=${BASH_SOURCE[0]}; fi
SCHED_DIR=${SCRIPT_DIR%/*/*} # take out /bin/vkconfig

if [ -z "$JAVA_HOME" ] ; then
    JAVA="java"
else
    JAVA=$JAVA_HOME/bin/java
fi

declare -a vkconfigopts=("$1")
shift
# parse opts
declare -a dockeropts
unset lastopt conf dbhost username
for opt in $VKCONFIG_OPTS "$@"; do
  if [[ $opt =~ ^-- ]]; then
    lastopt="${opt}"
  elif [[ -n $lastopt ]]; then
    case "$lastopt" in
      (--username)
          username=$opt
      ;;
      (--dbhost)
          dbhost=$opt
      ;;
      (--conf)
          conf=$opt
          opt=/etc/vkconfig.conf
      ;;
    esac
    unset lastopt
  fi
  vkconfigopts+=("$opt")
done

function fail {
  echo "$@" >&2
  exit 1;
}

if readlink -f . >/dev/null 2>/dev/null; then
  function abspath {
    readlink -f "$1" || fail "File does not exist ($1)"
  }
else
  function abspath {
    if [[ $1 =~ ^/ ]]; then
      [[ -r $1 ]] || fail "File does not exist ($1)"
      echo $1
    else
      [[ -r $PWD/$1 ]] || fail "File does not exist ($PWD/$1)"
      echo $PWD/$1
    fi
  }
fi

: ${LOG_CONFIG:=$SCHED_DIR/config/vkafka-log-config.xml}
if [[ -r $LOG_CONFIG ]]; then
  dockeropts+=( -v "$(abspath "$LOG_CONFIG"):/opt/vertica/packages/kafka/config/vkafka-log-config.xml" )
fi

if [[ -r $conf ]]; then
  dockeropts+=( -v "$(abspath $conf):/etc/vkconfig.conf" )
  # and look through $conf for some args that have a different meaning inside
  # the continer so they must be specified.
  set -e
  source $conf
  set +e
fi

# if dbhost isn't specified in the conf file or in the arguments, then it's
# localhost and that won't work inside a container.
if [[ -z $dbhost || localhost = $dbhost || 127.0.0.1 = $dbhost ]]; then
  vkconfigopts+=( --dbhost host.docker.internal )
  dockeropts+=( --add-host host.docker.internal:host-gateway )
fi

# if username isn't specified, then it takes the local username which is
# different in the container, so we need to specify it explicitly.
if [[ -z $username ]]; then
  vkconfigopts+=( --username $(id -un) )
fi

: ${LOG_DIR:=/opt/vertica/log}
if ! [[ -d $LOG_DIR ]] || [[ -w $LOG_DIR ]]; then # use /opt/vertica/log if it exists and is writable
  LOG_DIR=$PWD/log
  mkdir -p $PWD/log
fi
dockeropts+=( -v "$PWD/log:/opt/vertica/log" )

exec docker run -i "${dockeropts[@]}" \
    --user $(perl -E '@s=stat "'"$LOG_DIR"'"; say "$s[4]:$s[5]"') \
        vertica/kafka-scheduler:$VERTICA_VERSION vkconfig "${vkconfigopts[@]}"

