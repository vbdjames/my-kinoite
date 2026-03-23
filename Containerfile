# =============================================================================
# Custom Fedora Kinoite Image
# Base: quay.io/fedora/fedora-kinoite (official Fedora Atomic KDE image)
# =============================================================================

ARG FEDORA_VERSION=43
FROM quay.io/fedora/fedora-kinoite:${FEDORA_VERSION}

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
# 1PASSWORD
# Installed as a native RPM (not Flatpak) so the SSH agent works correctly.
# The Flatpak version cannot expose the agent socket outside the sandbox.
# =============================================================================
RUN echo -e "[1password]\nname=1Password Stable Channel\nbaseurl=https://downloads.1password.com/linux/rpm/stable/\$basearch\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://downloads.1password.com/linux/keys/1password.asc" \
        > /etc/yum.repos.d/1password.repo \
    && dnf install -y \
        1password \
        1password-cli \
    && dnf clean all
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

