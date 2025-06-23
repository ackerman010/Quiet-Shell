#!/usr/bin/env bash
set -euo pipefail

# ─── CONFIGURATION ────────────────────────────────────────────────────────────
REPO="https://github.com/ackerman010/Quiet-Shell.git"
DEST="$HOME/.config/Quiet-Shell"

# Only the COPR we know works for all hyprland tools + swww:
COPR="solopasha/hyprland"

# Fedora-42 package list (all names verified)
DNF_PKGS=(
  bash                # the wrapper
  curl                # used by install scripts
  git                 # for cloning/updating
  python3             # for the installer hooks
  python3-pip         # for any pure-Python modules
  python3-gobject
  python3-ijson
  python3-numpy
  python3-pillow
  python3-psutil
  python3-requests
  python3-setproctitle
  python3-toml
  python3-watchdog
  cliphist
  cava
  gnome-bluetooth
  gobject-introspection
  imagemagick
  libnotify
  noto-fonts-emoji
  nvtop
  playerctl
  swappy
  tesseract
  tmux
  unzip
  upower
  vte3
  webp-pixbuf-loader
  wl-clipboard
  # hyprland helpers & swww come from the COPR:
  hypridle hyprlock hyprpicker hyprshot hyprsunset swww polkit-gnome
)

# Pure-Python extras (installed with pip3 --user)
PIP_PKGS=(
  fabric
  pywayland
)

# ─── SAFETY ───────────────────────────────────────────────────────────────────
if [ "$EUID" -eq 0 ]; then
  echo "⚠️  Please do NOT run as root. Exiting." >&2
  exit 1
fi

# ─── ENABLE COPR ──────────────────────────────────────────────────────────────
echo "🔧 Enabling COPR repo: $COPR"
sudo dnf install -y dnf-plugins-core
sudo dnf copr enable -y "$COPR"

# ─── INSTALL SYSTEM PACKAGES ──────────────────────────────────────────────────
echo "📦 Installing Fedora packages (skipping any missing)…"
sudo dnf makecache
sudo dnf install -y --skip-broken "${DNF_PKGS[@]}"

# ─── INSTALL PIP MODULES ──────────────────────────────────────────────────────
echo "🐍 Installing Python modules (pip3 --user)…"
pip3 install --user "${PIP_PKGS[@]}"

# ─── FETCH OR UPDATE Quiet-Shell ──────────────────────────────────────────────
if [ -d "$DEST/.git" ]; then
  echo "🔄 Updating Quiet-Shell…"
  git -C "$DEST" pull --ff-only
else
  echo "📥 Cloning Quiet-Shell into $DEST…"
  git clone --depth=1 "$REPO" "$DEST"
fi

# ─── RUN THE UPSTREAM INSTALLER ───────────────────────────────────────────────
echo "⚙️  Invoking Quiet-Shell’s own install.sh…"
bash "$DEST/install.sh"

echo "✅ All set! Log out and back in (or restart your shell) to start using Quiet-Shell."
