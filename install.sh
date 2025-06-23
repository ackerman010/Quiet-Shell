#!/usr/bin/env bash
set -euo pipefail

# ─── Configuration ───────────────────────────────────────────────────────────
REPO_URL="https://github.com/Axenide/Ax-Shell.git"
INSTALL_DIR="$HOME/.config/Ax-Shell"

# COPR Repositories
COPRS=(
  solopasha/hyprland    # Hyprland utilities: hypridle, hyprlock, hyprpicker, hyprshot, hyprsunset, polkit agent  (solopasha/hyprland)
  materka/swww          # Animated wallpaper daemon and client (materka/swww)
)

# DNF packages (Fedora 42 names)
DNF_PKGS=(
  brightnessctl
  cava
  cliphist
  gnome-bluetooth
  gobject-introspection
  imagemagick
  libnotify
  matugen         # if unavailable, DNF will skip it
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
  # Hyprland utilities from COPR
  hypridle hyprlock hyprpicker hyprshot hyprsunset polkit-gnome-auth
  # swww from COPR
  swww
  # Python helpers
  python3-gobject
  python3-ijson
  python3-numpy
  python3-pillow
  python3-psutil
  python3-requests
  python3-setproctitle
  python3-toml
  python3-watchdog
)

# Python-only packages (installed via pip3 --user)
PIP_PKGS=(
  fabric      # fabric-cli-git
  pywayland
)

# Fonts
ZED_FONT_URL="https://github.com/zed-industries/zed-fonts/releases/download/1.2.0/zed-sans-1.2.0.zip"
ZED_FONT_DIR="$HOME/.local/share/fonts/zed-sans"
TABLER_SRC_DIR="$INSTALL_DIR/assets/fonts"
TABLER_DST_DIR="$HOME/.local/share/fonts/tabler-icons"

# ─── Safety checks ─────────────────────────────────────────────────────────────
if [ "$(id -u)" -eq 0 ]; then
  echo "⚠️  Please do not run this as root; re-run as your regular user."
  exit 1
fi

# ─── Enable COPR Repos ─────────────────────────────────────────────────────────
echo "🔧 Enabling COPR repos..."
sudo dnf install -y dnf-plugins-core
for c in "${COPRS[@]}"; do
  sudo dnf copr enable -y "$c"
done

# ─── Install system packages ──────────────────────────────────────────────────
echo "📦 Installing system packages via DNF..."
sudo dnf makecache
sudo dnf install -y "${DNF_PKGS[@]}" || true

# ─── Install Python modules via pip3 --user ────────────────────────────────────
echo "🐍 Installing Python modules (user)..."
if ! command -v pip3 &>/dev/null; then
  sudo dnf install -y python3-pip
fi
pip3 install --user "${PIP_PKGS[@]}"

# ─── Clone or update Ax-Shell repo ─────────────────────────────────────────────
if [ -d "$INSTALL_DIR/.git" ]; then
  echo "🔄 Updating Ax-Shell..."
  git -C "$INSTALL_DIR" pull --ff-only
else
  echo "📥 Cloning Ax-Shell into $INSTALL_DIR..."
  git clone --depth=1 "$REPO_URL" "$INSTALL_DIR"
fi

# ─── Install Zed-Sans fonts ───────────────────────────────────────────────────
if [ ! -d "$ZED_FONT_DIR" ]; then
  echo "🔤 Downloading & installing Zed-Sans fonts..."
  mkdir -p "$ZED_FONT_DIR"
  curl -L -o /tmp/zed-sans.zip "$ZED_FONT_URL"
  unzip -o /tmp/zed-sans.zip -d "$ZED_FONT_DIR"
  rm /tmp/zed-sans.zip
else
  echo "✅ Zed-Sans already installed."
fi

# ─── Install Tabler icon fonts ────────────────────────────────────────────────
if [ -d "$TABLER_SRC_DIR" ] && [ ! -d "$TABLER_DST_DIR" ]; then
  echo "🔤 Copying Tabler icon fonts..."
  mkdir -p "$TABLER_DST_DIR"
  cp -r "$TABLER_SRC_DIR/"* "$TABLER_DST_DIR/"
else
  echo "✅ Tabler icons already installed or not present."
fi

# ─── Refresh font cache ────────────────────────────────────────────────────────
echo "🔄 Refreshing font cache..."
fc-cache -f

# ─── Generate config and launch Ax-Shell ───────────────────────────────────────
echo "⚙️  Running Ax-Shell config script..."
python3 "$INSTALL_DIR/config/config.py"

echo "🚀 Starting Ax-Shell..."
pkill -f 'python3 .*/main.py' 2>/dev/null || true
nohup python3 "$INSTALL_DIR/main.py" >/dev/null 2>&1 & disown

echo "🎉 All done! Ax-Shell is now installed and running."
