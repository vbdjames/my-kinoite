# =============================================================================
# Custom Fedora Kinoite Image
# Base: quay.io/fedora/fedora-kinoite (official Fedora Atomic KDE image)
# =============================================================================

ARG FEDORA_VERSION=42

# =============================================================================
# AKMODS-EXTRA — prebuilt kernel modules from Universal Blue
# Used to provide evdi for DisplayLink support.
# =============================================================================
FROM ghcr.io/ublue-os/akmods-extra:main-42 AS akmods-extra

FROM quay.io/fedora/fedora-kinoite:${FEDORA_VERSION}

# =============================================================================
# DISPLAYLINK / EVDI
# evdi kernel module comes from Universal Blue's prebuilt akmods-extra image —
# compatible with ostree/immutable systems unlike the negativo17 akmod approach
# (akmods.service refuses to run when /run/ostree-booted exists).
# The displaylink userspace driver still comes from negativo17.
# =============================================================================
COPY --from=akmods-extra /rpms/ /tmp/rpms
RUN rpm-ostree install \
        /tmp/rpms/ublue-os/ublue-os-akmods*.rpm \
        /tmp/rpms/kmods/kmod-evdi*.rpm \
    && rm -rf /tmp/rpms \
    && rpm-ostree cleanup -m

RUN curl -Lo /etc/yum.repos.d/fedora-multimedia.repo \
        https://negativo17.org/repos/fedora-multimedia.repo \
    && rpm-ostree install displaylink \
    && systemctl enable displaylink.service \
    && rpm-ostree cleanup -m

# =============================================================================
# CONTAINER + DEV TOOLING
# =============================================================================
RUN rpm-ostree install \
        distrobox \
        podman-compose \
    && rpm-ostree cleanup -m

# =============================================================================
# GENERAL QUALITY-OF-LIFE PACKAGES
# Keep this minimal — prefer Flatpaks for GUI apps and distrobox for dev CLIs.
# =============================================================================
RUN rpm-ostree install \
        git \
        curl \
        wget \
        htop \
        fastfetch \
        zsh \
        stow \
        alacritty \
        neovim \
        tmux \
    && rpm-ostree cleanup -m

# =============================================================================
# REMOVE SYSTEM FIREFOX
# Replaced by the Flatpak version for better sandboxing and independent updates.
# =============================================================================
RUN rpm-ostree override remove firefox firefox-langpacks \
    && rpm-ostree cleanup -m

# =============================================================================
# FLATPAK REMOTE — Flathub
# Adds Flathub so Discover and `flatpak install` work out of the box.
# Actual Flatpak installs happen at runtime via dotfiles/install.sh.
# =============================================================================
RUN flatpak remote-add --if-not-exists flathub \
        https://dl.flathub.org/repo/flathub.flatpakrepo

# =============================================================================
# BOOTC LINT — catches common issues (stray files in /var, etc.)
# =============================================================================
RUN bootc container lint

