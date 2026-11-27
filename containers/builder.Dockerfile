# Callisto ISO builder image.
#
# Provides a hermetic Debian 13 (trixie) environment with live-build and all
# tooling required to produce callisto-amd64.hybrid.iso. The host distro and
# its package versions never leak into the build.
#
# Build:  podman build -f containers/builder.Dockerfile -t callisto-iso-builder .
# Use:    see scripts/build-iso.sh

FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        apt-utils \
        ca-certificates \
        curl \
        live-build \
        debootstrap \
        squashfs-tools \
        xorriso \
        isolinux \
        syslinux-common \
        grub-efi-amd64-bin \
        grub-pc-bin \
        mtools \
        dosfstools \
        zstd \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /live-build

# live-build must run as root inside the container; the image is never used
# as a runtime service, so no unprivileged user is created here.
ENTRYPOINT ["/bin/bash"]
