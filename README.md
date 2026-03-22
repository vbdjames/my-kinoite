# my-kinoite

A declarative, git-tracked custom [Fedora Kinoite](https://fedoraproject.org/atomic-desktops/kinoite/) image built as an OCI container.

**What this gives you:**

- Fedora Kinoite (KDE Plasma, atomic/immutable base)
- DisplayLink dock support via `kmod-evdi` + `displaylink` (negativo17 repo)
- `distrobox` for running dev tools in isolated containers
- Flathub enabled for GUI app installs
- Nightly auto-rebuild via GitHub Actions — your machine gets updates automatically

---

## Prerequisites

- A GitHub account
- Git installed locally (on your current machine, not the new one yet)

---

## Step 1 — Fork or create this repo on GitHub

1. Go to [github.com](https://github.com) and create a new **private** (or public) repository.
   Name it whatever you like, e.g. `my-kinoite`.
2. Clone this repo's files into it, or push this directory:

```bash
git init my-kinoite
cd my-kinoite
# copy these files in, then:
git add .
git commit -m "initial image config"
git remote add origin git@github.com:YOUR_USERNAME/my-kinoite.git
git push -u origin main
```

---

## Step 2 — Enable GitHub Actions write permissions

GitHub Actions needs permission to push the built image to the container registry (GHCR).

1. Go to your repo on GitHub → **Settings** → **Actions** → **General**
2. Scroll to **Workflow permissions** → select **Read and write permissions**
3. Click **Save**

The first build will trigger automatically on your `main` push. You can also trigger it manually under the **Actions** tab → **Build and Push OCI Image** → **Run workflow**.

---

## Step 3 — Make the package public (required for rpm-ostree to pull it)

After the first successful build:

1. Go to your GitHub profile → **Packages** → find your new image
2. Click **Package settings** → scroll to **Danger Zone** → **Change visibility** → set to **Public**

> **Why public?** The `rpm-ostree rebase` command pulls the image anonymously. Private images require auth setup that's more complex. You can make it private later once you configure credential helpers, but public is the easiest starting point.

---

## Step 4 — Install Fedora Kinoite

Download and install **vanilla Fedora Kinoite** from [fedoraproject.org/atomic-desktops/kinoite](https://fedoraproject.org/atomic-desktops/kinoite/).

Install it normally. You'll rebase to your custom image in the next step — the vanilla install is just a bootstrapping step.

---

## Step 5 — Rebase to your custom image

Once booted into vanilla Kinoite, open a terminal and run:

```bash
rpm-ostree rebase ostree-unverified-registry:ghcr.io/YOUR_USERNAME/my-kinoite:latest
```

Then reboot:

```bash
systemctl reboot
```

You're now running your custom image. Verify with:

```bash
rpm-ostree status
```

You should see `ghcr.io/YOUR_USERNAME/my-kinoite:latest` as the booted deployment.

---

## Step 6 — Verify DisplayLink

Plug in your dock, then check:

```bash
systemctl status displaylink-driver.service
lsmod | grep evdi
```

Both should show active/loaded. If not, see [Troubleshooting](#troubleshooting) below.

---

## Day-to-day usage

### Updating your OS

Your image rebuilds automatically every night via the GitHub Actions schedule. To pull and stage the latest image:

```bash
rpm-ostree upgrade
# then reboot when convenient
systemctl reboot
```

### Rolling back

If something breaks after an update:

```bash
rpm-ostree rollback
systemctl reboot
```

### Adding packages permanently

Edit `Containerfile`, add a `dnf install` line in the appropriate section, commit, and push. GitHub Actions will rebuild the image. Run `rpm-ostree upgrade` + reboot to get it.

### Installing GUI apps (Flatpaks)

Use **KDE Discover** or the command line:

```bash
flatpak install flathub com.visualstudio.code
flatpak install flathub org.mozilla.firefox
```

Flatpaks don't require a reboot and are not part of the image — they live in your home directory.

### Running dev tools in containers (Distrobox)

Instead of installing dev CLIs into the OS image, run them in containers:

```bash
# Create a Fedora dev container
distrobox create --name devbox --image fedora:latest
distrobox enter devbox

# Inside the container, install whatever you need
sudo dnf install nodejs golang python3 gh ...
```

The container has full access to your home directory and can run GUI apps. It persists across reboots. Create one per project/language if you want isolation.

---

## Customizing this image

The `Containerfile` is split into clearly labeled sections:

| Section | What to change |
|---|---|
| `ARG FEDORA_VERSION` | Bump when a new Fedora release is out |
| DisplayLink block | Don't touch unless negativo17 URL changes |
| Container tooling | Add `docker-compose`, `kubectl`, etc. here |
| Quality-of-life packages | Add system-level CLIs like `zsh`, `tmux`, `jq` |
| Flatpak remote | Add other remotes here if needed |

> **Rule of thumb:** if it's a GUI app → Flatpak. If it's a dev CLI → distrobox. If it must be on the host (daemon, kernel module, system CLI) → add it to the `Containerfile`.

---

## KDE Tiling

KDE Plasma has built-in tiling you can enable without installing anything extra:

1. Right-click the desktop → **Configure Desktop and Wallpaper** (or open System Settings)
2. Go to **Window Management** → **KWin Scripts**
3. Enable **Polonium** (available from Get New Scripts) for i3-style tiling, or use the built-in **Quarter Tiling**

Alternatively, **System Settings** → **Window Management** → **Window Tiling** has a native tiling mode in Plasma 6.

If you later decide you want a full tiling WM, you can rebase to `fedora-sway-atomic` without reinstalling — just change the `FROM` line in the `Containerfile`.

---

## Troubleshooting

### DisplayLink not working after an OS update

A kernel update can temporarily break `kmod-evdi` if negativo17 hasn't published a build for the new kernel yet.

**Option A — Roll back and wait:**
```bash
rpm-ostree rollback
systemctl reboot
# check back in a few days and upgrade again
```

**Option B — Pin the current good deployment:**
```bash
sudo ostree admin pin 0
# this prevents the pinned deployment from being garbage collected
```

### `rpm-ostree upgrade` says "No upgrade available"

Your image may not have rebuilt yet. Check the **Actions** tab on your GitHub repo to confirm the latest build succeeded. You can also trigger a manual rebuild there.

### Checking what's in your image

```bash
rpm-ostree status          # show current and staged deployments
rpm -qa | grep evdi        # confirm evdi package is installed
flatpak list               # show installed Flatpaks
distrobox list             # show running containers
```

---

## Repository structure

```
my-kinoite/
├── .github/
│   └── workflows/
│       └── build.yml      # GitHub Actions: build + push OCI image nightly
├── Containerfile           # The OS definition — edit this to customize
└── README.md               # This file
```
