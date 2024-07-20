#
# Dockerfile/Containerfile for building Teaclave Trustzone SDK
# in either an AMD64 or ARM64 container.
#
# Use 
# docker build -f ValidiTEE-build.containerFile --target build-rust-stage -t validitee-build-rust .
#
# Add `--platform linux/amd64` or `--platform linux/arm64` if you want to overide the
# default container architecture for your host.
#
# Author: Sean Gilligan https://github.com/msgilligan
# Date: 2024-06-03
#
FROM debian:bookworm-slim AS debian-config-stage
ARG DEBIAN_FRONTEND=noninteractive
ARG TARGETARCH

# Setup Environment for AMD64 build container
FROM debian-config-stage AS debian-config-amd64
ENV GCC64="gcc-aarch64-linux-gnu"
ENV CROSS_COMPILE="aarch64-linux-gnu-"
ENV CROSS_COMPILE64="aarch64-linux-gnu-"
ENV CROSS_COMPILE32="arm-linux-gnueabihf-"

# Setup Environment for ARM64 build container
FROM debian-config-stage AS debian-config-arm64
ENV GCC64="gcc"
ENV CROSS_COMPILE=""
ENV CROSS_COMPILE64=""
ENV CROSS_COMPILE32="arm-linux-gnueabihf-"

# Update and install APT packages based upon build container architecture
FROM debian-config-${TARGETARCH} as debian-stage
RUN apt update && apt upgrade -y
RUN apt install -y \
    adb \
    acpica-tools \
    autoconf \
    automake \
    bc \
    bison \
    build-essential \
    ccache \
    cpio \
    cscope \
    curl \
    device-tree-compiler \
    e2tools \
    expect \
    fastboot \
    flex \
    ftp-upload \
    gdisk \
    git \
    libattr1-dev \
    libcap-ng-dev \
    libfdt-dev \
    libftdi-dev \
    libglib2.0-dev \
    libgmp3-dev \
    libhidapi-dev \
    libmpc-dev \
    libncurses5-dev \
    libpixman-1-dev \
    libslirp-dev \
    libssl-dev \
    libtool \
    libusb-1.0-0-dev \
    make \
    mtools \
    netcat-openbsd \
    ninja-build \
    python3-cryptography \
    python3-pip \
    python3-pyelftools \
    python3-serial \
    python-is-python3 \
    rsync \
    swig \
    unzip \
    uuid-dev \
    wget \
    xdg-utils \
    xterm \
    xz-utils \
    zlib1g-dev \
    $GCC64 \
    gcc-arm-linux-gnueabihf 

FROM debian-stage AS rust-stage
# Install Rust
# Note that rustup is available as an Apt package in Trixie
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y && \
  . $HOME/.cargo/env && \
  rustup target install aarch64-unknown-linux-gnu && \
  rustup target install arm-unknown-linux-gnueabihf && \
  rustup default nightly-2023-12-18 && \
  rustup component add rust-src

ENV PATH="/root/.cargo/bin:$PATH"

# Check out OP-TEE OS and Client from GitHub
FROM rust-stage AS checkout-optee-stage
WORKDIR /
RUN mkdir /optee
WORKDIR /optee
RUN git clone https://github.com/OP-TEE/optee_os.git
RUN git clone https://github.com/OP-TEE/optee_client.git

# Build OP-TEE OS and Client
FROM checkout-optee-stage AS build-optee-stage
# Build OP-TEE OS
WORKDIR /optee/optee_os
RUN make PLATFORM=vexpress-qemu_armv8a
# Build OP-TEE client libraries
WORKDIR /optee/optee_client
RUN make WITH_TEEACL=0


FROM build-optee-stage AS setup-build-dir-stage

VOLUME ["/optee/optee_rust"]
WORKDIR /optee/optee_rust

ENV OPTEE_DIR="/optee"
ENV OPTEE_OS_DIR="$OPTEE_DIR/optee_os"
ENV OPTEE_CLIENT_DIR="$OPTEE_DIR/optee_client"
ENV OPTEE_CLIENT_EXPORT="$OPTEE_CLIENT_DIR/out/export"
ENV TA_DEV_KIT_DIR="$OPTEE_OS_DIR/out/arm-plat-vexpress/export-ta_arm64"
ENV TARGET="aarch64-unknown-linux-gnu"








