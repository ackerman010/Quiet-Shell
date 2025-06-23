#!/usr/bin/env bash
set -euo pipefail

# ─── VARIABLES ────────────────────────────────────────────────────────────────
REPO="https://github.com/ackerman010/Quiet-Shell.git"
DEST="$HOME/.config/Quiet-Shell"

# COPR repos (same ones upstream installer uses)
COPRS=(
  solopasha/hyprland    # hypridle, hyprlock, hyprpicker, hyprshot, hyprsunset, polkit-gnome-auth
  materka/swww          # animated wallpaper daemon (optional)
)

# Fedora packages (replace any you don’t need)
DNF_PKGS=(
  bash             # Quiet-Shell is a bash wrapper
  python3          # for the installer hooks
  python3-pip      # pip for any missing modules
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
  matugen       # may not exist, skipped if missing
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
  # Hyprland helpers from COPR:
  hypridle hyprlock hyprpicker hyprshot hyprsunset polkit-gnome-auth
  # swww from COPR:
  swww
)

# Python-only extras (installed with pip3 --user)
PIP_PKGS=(
  fabric        # fabric-cli
  pywayland
)

# ─── SAFETY ───────────────────────────────────────────────────────────────────
if [ "$EUID" -eq 0 ]; then
  echo "⚠️  Please don’t run this as root. Exiting."
  exit 1
fi

# ─── ENABLE COPRs ─────────────────────────────────────────────────────────────
echo "🔧 Enabling COPR repos…"
sudo dnf install -y dnf-plugins-core
for c in "${COPRS[@]}"; do
  sudo dnf copr enable -y "$c"
done

# ─── INSTALL SYSTEM PACKAGES ──────────────────────────────────────────────────
echo "📦 Installing system packages via DNF…"
sudo dnf makecache
sudo dnf install -y "${DNF_PKGS[@]}" || true

# ─── INSTALL PIP MODULES ──────────────────────────────────────────────────────
echo "🐍 Installing Python modules (pip3 --user)…"
pip3 install --user "${PIP_PKGS[@]}"

# ─── CLONE / UPDATE Quiet-Shell ───────────────────────────────────────────────
if [ -d "$DEST/.git" ]; then
  echo "🔄 Updating Quiet-Shell…"
  git -C "$DEST" pull --ff-only
else
  echo "📥 Cloning Quiet-Shell to $DEST…"
  git clone --depth=1 "$REPO" "$DEST"
fi

# ─── RUN THE UPSTREAM INSTALLER ───────────────────────────────────────────────
echo "⚙️  Running Quiet-Shell’s bundled installer…"
bash "$DEST/install.sh"

echo "✅ All done! Log out and back in (or source your shell) to start using Quiet-Shell."
