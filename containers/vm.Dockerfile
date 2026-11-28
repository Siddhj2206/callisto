# QEMU for scripts/vm.py, so that every host boots the image with the same QEMU
# and the same virglrenderer, whatever it has installed itself. 3D in the guest
# is rendered by this Mesa on the host's /dev/dri render node.

FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        qemu-system-x86 \
        qemu-system-gui \
        qemu-system-modules-opengl \
        libegl1 libegl-mesa0 libgl1 libgles2 libgbm1 libgl1-mesa-dri \
        xorriso \
    && rm -rf /var/lib/apt/lists/*
