# Callisto shell test environment.
#
# Runs the Triton shell (Quickshell QML) inside a nested sway instance without
# booting the full ISO — the fast inner development loop for all shell/ work.
# The compositor appears as a window in the host's Wayland session; the shell
# sources are bind-mounted in, so edits are picked up by restarting the
# container, which takes seconds.
#
# sway stands in for Hyprland here: it implements the same layer-shell
# protocol, nests cleanly as a Wayland client with no seat/DRM requirements,
# and is packaged in trixie main. What it cannot test is Hyprland-specific IPC
# (workspace pills); that integration is verified in QEMU against the ISO.
#
# Build:  podman build -f containers/shelltest.Dockerfile -t callisto-shelltest .
# Run:    scripts/test-shell.sh

FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

# quickshell needs backports pinning; sway and the rest are in stable.
RUN echo 'deb http://deb.debian.org/debian trixie-backports main contrib non-free-firmware' \
        > /etc/apt/sources.list.d/backports.list \
    && printf 'Package: quickshell hyprland libaquamarine* libhypr* libxkbcommon* libinput* libwayland*\nPin: release n=trixie-backports\nPin-Priority: 600\n' \
        > /etc/apt/preferences.d/backports-pin \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        quickshell \
        hyprland \
        sway \
        xwayland \
        foot \
        fonts-jetbrains-mono \
        fonts-inter \
        fonts-noto-color-emoji \
        qt6-declarative-dev-tools \
        qt6-wayland \
        qml6-module-qtquick-effects \
        grim \
        wtype \
        jq \
        python3 \
        curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -u 1000 -s /bin/bash triton

# matugen: same upstream release binary the ISO hook fetches — the harness
# must run the real theme pipeline, not a degraded copy of it.
COPY configs/matugen.env /tmp/matugen.env
RUN . /tmp/matugen.env \
    && curl -fsSL --retry 3 --max-time 120 -o /tmp/matugen.tar.gz \
        "https://github.com/InioX/matugen/releases/download/$MATUGEN_VERSION/matugen-${MATUGEN_VERSION#v}-x86_64.tar.gz" \
    && echo "$MATUGEN_SHA256  /tmp/matugen.tar.gz" | sha256sum -c - \
    && tar -xzf /tmp/matugen.tar.gz -C /usr/local/bin matugen \
    && chmod 0755 /usr/local/bin/matugen \
    && rm -f /tmp/matugen.tar.gz /tmp/matugen.env

# The theme engine, system tokens and wallpaper mirror the ISO layout exactly.
COPY bin/callisto-apply /usr/local/bin/callisto-apply
COPY design/tokens.json /usr/share/callisto/tokens.json
COPY configs/callisto/default-settings.json /usr/share/callisto/default-settings.json
COPY design/wallpaper.jpg /usr/share/backgrounds/callisto/wallpaper.jpg
RUN chmod 0755 /usr/local/bin/callisto-apply

COPY containers/shelltest-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER triton

ENTRYPOINT ["/entrypoint.sh"]
