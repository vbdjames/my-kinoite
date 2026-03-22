# =============================================================================
# Custom Fedora Kinoite Image
# Base: quay.io/fedora/fedora-kinoite (official Fedora Atomic KDE image)
# =============================================================================

ARG FEDORA_VERSION=42
FROM quay.io/fedora/fedora-kinoite:${FEDORA_VERSION}

# =============================================================================
# DISPLAYLINK / EVDI
# Uses negativo17's fedora-multimedia repo which provides pre-built kmod-evdi
# packages (no DKMS required — compatible with rpm-ostree/atomic images).
#
# Note: repo file is added manually to /etc/yum.repos.d/ first, then
# rpm-ostree install is used (not dnf — dnf is not available in Kinoite
# container builds).
# =============================================================================
RUN curl -Lo /etc/yum.repos.d/fedora-multimedia.repo \
        https://negativo17.org/repos/fedora-multimedia.repo \
    && rpm-ostree install \
        kmod-evdi \
        displaylink \
    && systemctl enable displaylink-driver.service \
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
