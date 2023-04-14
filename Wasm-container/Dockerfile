# -*- mode: shell-script -*-
# (c) Copyright [2021-2023] OpenText.
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
############################################################################

# Base operating system
ARG os_version="120.04"

FROM ubuntu:${os_version} as builder

# useful to keep dpkg from prompting us for information
ENV DEBIAN_FRONTEND noninteractive
ENV TERM 1

ENV VERTICA_OPT_DIR="/opt/vertica"
ENV VERTICA_VOLUME_DIR="/vwasmdata"
ENV VERTICA_DATA_DIR="${VERTICA_VOLUME_DIR}/vertica"
ENV VERTICA_DB_NAME="vwasmsdk"

# required for Ubuntu because the Vertica installer and some of the
# Rust and Wasm tool installers use bash syntax instead of the syntax
# used by the default shell 
ENV SHELL "/bin/bash"

ARG vertica_db_user="dbadmin"
ARG vertica_db_group="verticadba"
ARG dbadmin_gid=1000
ARG dbadmin_id=1000

# name of .deb file
ARG DEB
ARG vertica_version

COPY $DEB /tmp/$DEB
COPY ./tools/cleanup.sh /tmp/
COPY ./tools/package-checksum-patcher.py /tmp/

# Create DB user and group in OS. Fix their ID, so they match in the following stage
RUN set -x \
 # Install those things needed for a Vertica installation    
 && apt-get update -y \
 && apt-get upgrade --no-install-recommends -y \
 && apt-get install --no-install-recommends -yqq \
            bash \
            curl \
            ca-certificates \
            dialog \
            iproute2 \
            libexpat1 \
            locales \
            ntp \
            openssh-client \
            openssh-server \
            sysstat \
 && chsh -s /bin/bash root \
 # Fix locales
 && /bin/echo "en_US ISO-8859-1" > /etc/locale.gen \
 && /bin/echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
 && /usr/sbin/locale-gen \
 && mkdir -p ${VERTICA_DATA_DIR} \
 # Create DB user and group in OS. Fix their ID, so they match in the following stage
 && /usr/sbin/groupadd -r -g $dbadmin_gid $vertica_db_group \
     && /usr/sbin/useradd \
            -r \
            -m \
            -s /bin/bash \
            -g $vertica_db_group \
            -u $dbadmin_id \
            $vertica_db_user 

# Install Vertica package
RUN set -x \
 && dpkg -i /tmp/${DEB} \
 && mkdir -p ${VERTICA_DATA_DIR} \
 && ${VERTICA_OPT_DIR}/sbin/install_vertica \
                      --accept-eula \
                      --data-dir $VERTICA_DATA_DIR \
                      --dba-group $vertica_db_group \
                      --dba-user $vertica_db_user \
                      --dba-user-password-disabled \
                      --debug \
                      --failure-threshold NONE \
                      --hosts 127.0.0.1 \
                      --ignore-aws-instance-type \
                      --ignore-install-config \
                      --license CE \
                      --no-system-configuration \
                      --point-to-point \
                      --no-ssh-key-install \
                      -U

RUN chown -R $vertica_db_user:$vertica_db_group $VERTICA_OPT_DIR \
    && chown -R $vertica_db_user:$vertica_db_group /home/$vertica_db_user

# docker daemons versions < 19.03 don't preserve ownership on COPY --from
# but doing the chown -R in the second half is costly in terms of
# image size, so we compromise by making everything group writable in
# /opt/vertica:
RUN chmod -R g+w ${VERTICA_OPT_DIR}

RUN sh /tmp/cleanup.sh

###########################################################################
ARG os_version="20.04"

FROM ubuntu:${os_version} 

ARG vertica_db_user="dbadmin"
ARG vertica_db_group="verticadba"

ARG dbadmin_gid=1000
ARG dbadmin_id=1000

# useful to keep dpkg from prompting us for information
ENV DEBIAN_FRONTEND noninteractive
ENV TERM 1

ENV VERTICA_OPT_DIR="/opt/vertica"
ENV VERTICA_OPT_BIN="${VERTICA_OPT_DIR}/bin"
ENV VERTICA_HOME_DIR="/home/$vertica_db_user"
ENV VERTICA_VOLUME_DIR="/vwasmdata"
ENV VERTICA_DATA_DIR="${VERTICA_VOLUME_DIR}/vertica"
ENV VERTICA_DB_NAME="vwasmsdk"
ENV PYTHON_EGG_CACHE="/tmp/.python-eggs"

ENV TEMPLATE /usr/WebAssembly/template
ENV TOOLDIR ${TEMPLATE}/tools
ENV SHELL "/bin/bash"

COPY --from=builder $VERTICA_OPT_DIR $VERTICA_OPT_DIR
COPY --from=builder $VERTICA_DATA_DIR $VERTICA_DATA_DIR

COPY ./tools/init.d.functions /etc/rc.d/init.d/functions

ADD ./tools/package-checksum-patcher.py /tmp/
ADD ./tools/init.d.functions /etc/rc.d/init.d/functions

# Install prerequisites, create Vertica data dir, document fix
# timezone issue, set privileges, limits and generate locales  
RUN set -x \
 # COPY doesn't preserve the mode of the top-level
 && chmod g+w ${VERTICA_OPT_DIR} \
 && /usr/sbin/groupadd -r -g $dbadmin_gid $vertica_db_group \
 && /usr/sbin/useradd -r \
                      -m \
                      -s /bin/bash \
                      -g $vertica_db_group \
                      # add dbadmin to root to work around COPY
                      # not preserving owner and group prior to
                      # docker version 19.03
                      -G root \
                      -u $dbadmin_id \
                      $vertica_db_user \
 && su - $vertica_db_user -c "mkdir $PYTHON_EGG_CACHE" \
# Install prerequisites, create Vertica data dir, set privileges, document
# fix timezone issue and generate locales in case of centOS 8 
 && apt-get update -y \
 && apt-get upgrade --no-install-recommends -y \
 && apt-get install -y \
            autotools-dev \
            bash \
            binutils \
            build-essential \
            ca-certificates \
            clang \
            cmake \
            curl \
            dialog \
            doxygen \
            expat \
            flex \
            g++ \
            gcc \
            gdb \
            gettext \
            git \
            gpg-agent \
            iproute2 \
            libacl1-dev \
            libboost-all-dev \
            libbz2-dev \
            libc-dev \
            libc6-dev-i386 \
            libcurl4-openssl-dev \
            libgomp1 \
            libicu-dev \
            libkeyutils1 \
            libreadline-dev \
            libtinfo5 \
            libtool \
            lld \
            locales \
            lsb-release \
            make \
            nasm \
            ninja-build \
            ntp \
            openssl \
            procps \
            python3 \
            python3-pip \
            software-properties-common \
            sudo \
            sysstat \
            tar \
            vim \
            wabt \
            wget \
 && chsh -s /bin/bash root \
 && /bin/echo "en_US ISO-8859-1" > /etc/locale.gen \
 && /bin/echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
 && /usr/sbin/locale-gen \
 && echo "${vertica_db_user} -       nice    0" >> /etc/security/limits.conf \
 && echo "${vertica_db_user} -       nofile  65536" >> /etc/security/limits.conf \
 # Allow passwordless sudo access from dbadmin
 && echo "$vertica_db_user ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers \
     # docker daemons versions < 19.03 don't preserve ownership on COPY --from
     # so we have to chown these things again
     && chown -R $vertica_db_user:$vertica_db_group ${VERTICA_DATA_DIR} \
     && chown -R $vertica_db_user:$vertica_db_group /home/$vertica_db_user \
     # but this chown is expensive in image-size, so we use aother
     # trick in the first half of the build 
     # && chown -R $vertica_db_user:$vertica_db_group ${VERTICA_OPT_DIR} \
 && apt remove --purge -y libpython2.7

# vertica v10 (and earlier, but 10 is what we're interested in enough
# to test) vertica_agent script uses the rpm command to find out where
# Vertica is installed.  But we threw the 900-1200 MB of rpm info away
# when we did the multi-stage build.  v11 and subsequent used a
# different technique more compatible with what we're doing with
# containers 
ADD ./tools/vertica_agent.11 /tmp/
ADD ./tools/vertica_agent_patch.sh /tmp/
RUN bash /tmp/vertica_agent_patch.sh

COPY entrypoint.sh /opt/vertica/bin/entrypoint.sh

##################################################################
# Wasm and Rust tools
# instructions for llvm for Ubuntu from https://apt.llvm.org/
WORKDIR /usr/WebAssembly/llvm
RUN curl https://apt.llvm.org/llvm.sh | bash -x 

# This may not be necessary since llvm and Rust don't depend on
# emscripten
WORKDIR /usr/WebAssembly/
RUN git clone https://github.com/emscripten-core/emsdk.git
WORKDIR /usr/WebAssembly/emsdk
RUN ./emsdk install latest

WORKDIR /usr/WebAssembly/wasmer
RUN sh -c 'curl https://get.wasmer.io -sSfL | sh'

# This is the result of a Rust newbie feeling their way to a proper installation 
RUN mkdir ${TEMPLATE} ${TOOLDIR} 

WORKDIR /usr/WebAssembly/rust
COPY reinstall-rust ${TOOLDIR}/reinstall-rust
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y \
    && chmod +x ${TOOLDIR}/reinstall-rust \
    && ${TOOLDIR}/reinstall-rust $HOME 

# I haven't gotten the python wasmer tools to work yet
# RUN pip3 install wasmer wasmer_compiler_cranelift wasmer_compiler_singlepass wasmer_compiler_llvm

# These are scripts described in the README --- a template for the user's
# environment is created in $HOME (/) owned by the container root.
# For the user to do stuff, they copy the template into their own home
# directory.
# (Probably could bypass the `cp -r` by defining the HOME envar to be
# /usr/WebAssembly/template at the start of the Dockerfile.)
RUN cp -r $HOME/.cargo ${TEMPLATE} \
    && cp -r $HOME/.wasmer ${TEMPLATE} \
    && chmod -R a+r,a+X ${TEMPLATE}

# useful scripts for users
COPY copy-template-to-sandbox ${TOOLDIR}
COPY wasm-env-setup ${TOOLDIR}
RUN chmod +x ${TOOLDIR}/copy-template-to-sandbox
# Example use of the tools
COPY examples /usr/WebAssembly/vertica

# DB is running under vertica_db_user, not under root
USER $vertica_db_user

WORKDIR ${VERTICA_HOME_DIR}

VOLUME ${VERTICA_VOLUME_DIR}

ENTRYPOINT  [ "/opt/vertica/bin/entrypoint.sh" ]

# vertica port
EXPOSE 5433
# vertica agent port
EXPOSE 5444

LABEL image_name="vertica_wasm_udx_development"
LABEL os_family="$CONTAINER_OS"
LABEL os_version="$CONTAINER_OS_VERSION"
LABEL vertica_version="$VERTICA_VERSION"
LABEL maintainer="Vertica SDK Team"

