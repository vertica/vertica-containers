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

# required for Ubuntu because Vertica installer insists on it
ENV SHELL "/bin/bash"

# Create DB user and group in OS. Fix their ID, so they match in the following stage
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
            procps \
            python3 \
            python3-pip \
            software-properties-common \
            sudo \
            tar \
            vim \
            wget \
 && chsh -s /bin/bash root 

# instructions for Ubuntu from https://apt.llvm.org/
WORKDIR /usr/WebAssembly/llvm
RUN wget https://apt.llvm.org/llvm.sh
RUN bash -x ./llvm.sh

WORKDIR /usr/WebAssembly/
RUN git clone https://github.com/emscripten-core/emsdk.git
WORKDIR /usr/WebAssembly/emsdk
RUN ./emsdk install latest

WORKDIR /usr/WebAssembly/wasmer
RUN sh -c 'curl https://get.wasmer.io -sSfL | sh'

WORKDIR /usr/WebAssembly/rust
RUN curl https://sh.rustup.rs -sSf -o get-rustup \
    && sh ./get-rustup -y \
    && $HOME/.cargo/bin/rustup update \
    && $HOME/.cargo/bin/rustup target add wasm32-unknown-unknown --toolchain stable \
    && $HOME/.cargo/bin/rustup target add wasm32-wasi --toolchain stable \
    && $HOME/.cargo/bin/rustup install stable 

RUN mkdir /usr/WebAssembly/template \
    && cp -r $HOME/.cargo /usr/WebAssembly/template \
    && cp -r $HOME/.wasmer /usr/WebAssembly/template \
    && chmod -R a+r,a+X /usr/WebAssembly/template

# WORKDIR somewhere useful
# 
LABEL image_name="vertica_wasm_udx_development"
LABEL maintainer="SDK Team"
