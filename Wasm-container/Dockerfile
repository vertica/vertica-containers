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
############################################################################

# Base operating system
ARG os_version="20.04"

FROM ubuntu:${os_version} as builder

# useful to keep dpkg from prompting us for information
ENV DEBIAN_FRONTEND noninteractive
ENV TERM 1

# required for Ubuntu because some of the Rust and Wasm tool installers
# use bash syntax instead of the syntax used by the default shell
ENV SHELL "/bin/bash"

# Load tools and the things needed to build them
# (Some of these things might be dispensed with)
RUN set -x \
 && apt-get update -y \
 && apt-get upgrade --no-install-recommends -y \
 && apt-get install --no-install-recommends -yqq \
            autotools-dev \
            bash \
            binutils \
            build-essential \
            ca-certificates \
            clang \
            cmake \
            curl \
            doxygen \
            expat \
            flex \
            g++ \
            gcc \
            gdb \
            gettext \
            gpg-agent \
            git \
            libc-dev \
            libc6-dev-i386 \
            libtool \
            libtinfo5 \
            lld \
            locales \
            lsb-release \
            make \
            nasm \
            ninja-build \
            procps \
            python3 \
            python3-pip \
            software-properties-common \
            sudo \
            tar \
            vim \
            wabt \
            wget \
 && chsh -s /bin/bash root

# instructions for llvm for Ubuntu from https://apt.llvm.org/
WORKDIR /usr/WebAssembly/llvm
RUN wget https://apt.llvm.org/llvm.sh
RUN bash -x ./llvm.sh

# This may not be necessary since llvm and Rust don't depend on
# emscripten
WORKDIR /usr/WebAssembly/
RUN git clone https://github.com/emscripten-core/emsdk.git
WORKDIR /usr/WebAssembly/emsdk
RUN ./emsdk install latest

WORKDIR /usr/WebAssembly/wasmer
RUN sh -c 'curl https://get.wasmer.io -sSfL | sh'

# This is the result of a Rust newbie feeling their way to a proper installation 
WORKDIR /usr/WebAssembly/rust
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y \
    && $HOME/.cargo/bin/rustup toolchain install stable \
    && $HOME/.cargo/bin/rustup update \
    && $HOME/.cargo/bin/rustup target add wasm32-unknown-unknown --toolchain stable \
    && $HOME/.cargo/bin/rustup target add wasm32-wasi --toolchain stable \
    && $HOME/.cargo/bin/rustup target add x86_64-unknown-linux-gnu --toolchain stable

# I haven't gotten the python wasmer tools to work yet
# RUN pip3 install wasmer wasmer_compiler_cranelift wasmer_compiler_singlepass wasmer_compiler_llvm

# These are scripts described in the README --- a template for the user's
# environment is created in $HOME (/) owned by the container root.
# For the user to do stuff, they copy the template into their own home
# directory.
# (Probably could bypass the `cp -r` by defining the HOME envar to be
# /usr/WebAssembly/template at the start of the Dockerfile.)
RUN mkdir /usr/WebAssembly/template /usr/WebAssembly/template/tools \
    && cp -r $HOME/.cargo /usr/WebAssembly/template \
    && cp -r $HOME/.wasmer /usr/WebAssembly/template \
    && chmod -R a+r,a+X /usr/WebAssembly/template

# useful scripts for users
COPY copy-template-to-sandbox /usr/WebAssembly/template/tools
COPY wasm-env-setup /usr/WebAssembly/template/tools
RUN chmod +x /usr/WebAssembly/template/tools/copy-template-to-toolbox
# Example use of the tools
COPY examples /usr/WebAssembly/vertica

# put the WORKDIR someplace predictable
WORKDIR /usr/WebAssembly/vertica
# 
LABEL image_name="vertica_wasm_udx_development"
LABEL maintainer="Vertica SDK Team"
