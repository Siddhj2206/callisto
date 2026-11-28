# Debian's Hyprland with the patches in patches/hyprland applied, as a .deb in
# /out. scripts/build-debs.sh runs it.
#
# Drop all of this once trixie-backports has Hyprland 0.56 or later, which has
# the fix.

FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

# Backports as it was when Debian built this version: its libraries have since
# moved on to newer sonames, which the rest of this Hyprland stack does not use.
# Only what the image also takes from backports (backports.pref.chroot) comes
# from there, or the package would not install on it.
ARG SOURCE=0.55.2+ds-1~bpo13+1
ARG SNAPSHOT=20260604T204126Z

RUN archive=http://snapshot.debian.org/archive/debian/$SNAPSHOT \
    && printf '%s\n' \
        "deb [check-valid-until=no] $archive trixie-backports main" \
        "deb-src [check-valid-until=no] $archive trixie-backports main" \
        > /etc/apt/sources.list.d/snapshot.list \
    && printf 'Package: %s\nPin: release n=trixie-backports\nPin-Priority: 600\n' \
        'src:hypr* src:aquamarine src:libxkbcommon src:libinput src:wayland src:wayland-protocols src:glaze' \
        > /etc/apt/preferences.d/backports \
    && apt-get -o Acquire::Retries=5 update \
    && apt-get -o Acquire::Retries=5 install -y --no-install-recommends build-essential dpkg-dev quilt \
    && mkdir /build && cd /build \
    && apt-get -o Acquire::Retries=5 source "hyprland=$SOURCE" \
    && apt-get -o Acquire::Retries=5 build-dep -y "hyprland=$SOURCE"

COPY patches/hyprland /patches

# The version sorts above Debian's, so apt keeps ours until Debian's next one.
RUN cd /build/hyprland-*/ \
    && mkdir -p debian/patches /out \
    && for patch in /patches/*.patch; do \
        cp "$patch" debian/patches/ && echo "${patch##*/}" >> debian/patches/series; \
    done \
    && { printf 'hyprland (%s+callisto1) trixie-backports; urgency=medium\n\n  * Callisto: patches/hyprland.\n\n -- Callisto <noreply@callisto.invalid>  %s\n\n' \
             "$(dpkg-parsechangelog -S Version)" "$(dpkg-parsechangelog -S Date)"; \
         cat debian/changelog; } > changelog && mv changelog debian/changelog \
    && QUILT_PATCHES=debian/patches quilt push -a \
    && DEB_BUILD_OPTIONS="noautodbgsym nocheck parallel=$(nproc)" dpkg-buildpackage -B -us -uc \
    && cp ../hyprland_*_amd64.deb /out/
