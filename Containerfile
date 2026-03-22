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
# =============================================================================
RUN dnf config-manager addrepo \
        --from-repofile=https://negativo17.org/repos/fedora-multimedia.repo \
        --overwrite \
    && dnf install -y \
        kmod-evdi \
        displaylink \
    && dnf clean all \
    && systemctl enable displaylink-driver.service

# =============================================================================
# CONTAINER + DEV TOOLING
# distrobox  — richer container shells than toolbx, great for dev environments
# toolbox     — Fedora's native container shell tool (already in base, ensure present)
# podman      — already in base; listed here for clarity
# docker-compose — useful for running compose stacks from inside distrobox
# =============================================================================
RUN dnf install -y \
        distrobox \
        podman-compose \
    && dnf clean all

# =============================================================================
# GENERAL QUALITY-OF-LIFE PACKAGES
# Add or remove to taste. Keep this list minimal — prefer Flatpaks for GUI apps
# and distrobox containers for dev CLIs.
# =============================================================================
RUN dnf install -y \
        git \
        curl \
        wget \
        htop \
        fastfetch \
        zsh \
        stow \
    && dnf clean all

# =============================================================================
# FLATPAK REMOTE — Flathub
# The base Kinoite image only includes the Fedora Flatpak remote.
# This adds Flathub so you can install apps via Discover or `flatpak install`.
# Note: actual Flatpak installs happen at runtime (post-reboot), not here.
# =============================================================================
RUN flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# =============================================================================
# BOOTC LINT — catches common issues (stray files in /var, etc.)
# Remove this line if it causes build failures on older tooling.
# =============================================================================
RUN bootc container lint
