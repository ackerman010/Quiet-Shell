#!/bin/bash

set -e      # Exit immediately if a command fails
set -u      # Treat unset variables as errors
set -o pipefail  # Prevent errors in a pipeline from being masked

REPO_URL="https://github.com/Axenide/Ax-Shell.git"
INSTALL_DIR="$HOME/.config/Ax-Shell"

# DNF packages available in official Fedora repositories
DNF_PACKAGES=(
    brightnessctl
    cava
    gnome-bluetooth          # Equivalent to gnome-bluetooth-3.0 (runtime)
    gnome-bluetooth-libs-devel # Development files for gnome-bluetooth (added based on dnf search)
    gobject-introspection
    ImageMagick              # Equivalent to imagemagick
    libnotify
    google-noto-color-emoji-fonts # Equivalent to noto-fonts-emoji
    nvtop
    playerctl
    python3-fabric           # Equivalent to python-fabric-git, provides stable Fabric
    python3-gobject          # Equivalent to python-gobject
    python3-ijson            # Equivalent to python-ijson
    python3-numpy            # Equivalent to python-numpy
    python3-pillow           # Equivalent to python-pillow
    python3-psutil           # Equivalent to python-psutil
    python3-pywayland        # Equivalent to python-pywayland
    python3-requests         # Equivalent to python-requests
    python3-setproctitle     # Equivalent to python-setproctitle
    python3-toml             # Equivalent to python-toml
    python3-watchdog         # Equivalent to python-watchdog
    swappy
    tesseract
    tmux
    unzip
    upower
    vte3                     # Equivalent to vte3
    gdk-pixbuf2-modules      # Provides WebP support for GTK applications (replaces webp-pixbuf-loader)
    wl-clipboard
)

# Packages that typically require COPR repositories on Fedora
# These are often development versions or niche tools.
COPR_PACKAGES=(
    cliphist
    gpu-screen-recorder
    hypridle
    hyprlock
    hyprpicker
    hyprshot
    hyprsunset
    swww
    nerd-fonts               # For ttf-nerd-fonts-symbols-mono (installs a collection of Nerd Fonts)
)

# Packages that are specific to the original Arch setup or less common,
# and may need to be built from source or installed manually on Fedora.
BUILD_FROM_SOURCE_PACKAGES=(
    matugen     # Original: matugen-bin. A Python project.
    gray        # Original: gray-git. A theme by Axenide.
    uwsm        # Wayland Session Manager by Axenide, a dependency of Ax-Shell itself.
)

# Prevent running as root for safety
if [ "$(id -u)" -eq 0 ]; then
    echo "Please do not run this script as root."
    exit 1
fi

echo "Updating DNF package cache..."
sudo dnf check-update || true # Allow check-update to fail without stopping script if no updates are available

# Enable necessary COPR repositories
# These COPRs provide many of the Hyprland-related and other tools.
echo "Enabling COPR repositories..."
# COPR for Hyprland and related tools (hypridle, hyprlock, hyprpicker, hyprshot, hyprsunset, swww)
sudo dnf copr enable ryuuts/hyprland -y || { echo "Error: Failed to enable ryuuts/hyprland COPR. Please check your internet connection and try again. Exiting."; exit 1; }
# COPR for cliphist
sudo dnf copr enable atim/cliphist -y || { echo "Error: Failed to enable atim/cliphist COPR. Please check your internet connection and try again. Exiting."; exit 1; }
# COPR for gpu-screen-recorder
sudo dnf copr enable atim/gpu-screen-recorder -y || { echo "Error: Failed to enable atim/gpu-screen-recorder COPR. Please check your internet connection and try again. Exiting."; exit 1; }
# COPR for Nerd Fonts (replaces ttf-nerd-fonts-symbols-mono)
sudo dnf copr enable atim/nerd-fonts -y || { echo "Error: Failed to enable atim/nerd-fonts COPR. Please check your internet connection and try again. Exiting."; exit 1; }

# Install required DNF packages and COPR packages
echo "Installing required DNF and COPR packages..."
# Using --allowerasing can resolve conflicts but use with caution. -y for non-interactive install.
sudo dnf install -y "${DNF_PACKAGES[@]}" "${COPR_PACKAGES[@]}" || { echo "Warning: Some DNF/COPR packages failed to install. Continuing with the script."; }

# Clone or update the Ax-Shell repository
if [ -d "$INSTALL_DIR" ]; then
    echo "Updating Ax-Shell..."
    git -C "$INSTALL_DIR" pull
else
    echo "Cloning Ax-Shell..."
    git clone --depth=1 "$REPO_URL" "$INSTALL_DIR"
fi

# --- Manual Installation Instructions ---
echo ""
echo "--- Manual Installation May Be Required ---"
echo "The following packages are not directly available via DNF or common COPRs."
echo "You might need to install them manually or build them from source."

# Instructions for matugen
echo ""
echo "- matugen (Original: matugen-bin): This is a Python-based utility."
echo "  You might be able to install it via pip or clone its repository and run it directly."
echo "  To install via pip (recommended if available):"
echo "    pip install matugen"
echo "  Or, to clone and use:"
echo "    git clone https://github.com/material-foundation/matugen.git ~/matugen-source"
echo "    # Follow matugen's specific installation/usage instructions."

# Instructions for gray
echo ""
echo "- gray (Original: gray-git): This appears to be a theme or utility specific to Axenide's projects."
echo "  Please refer to its GitHub repository for installation instructions, or manually place its files."
echo "  GitHub: https://github.com/Axenide/gray"

# Instructions for uwsm
echo ""
echo "- uwsm (Wayland Session Manager): This is a critical dependency for Ax-Shell and likely needs to be built from source."
echo "  Please refer to its GitHub repository for detailed build instructions:"
echo "  GitHub: https://github.com/Axenide/uwsm"
echo "  Example basic build steps (may vary):"
echo "    sudo dnf install -y meson ninja-build gcc pkg-config wayland-protocols-devel libinput-devel libxkbcommon-devel"
echo "    git clone https://github.com/Axenide/uwsm.git ~/uwsm-source"
echo "    cd ~/uwsm-source"
echo "    meson build"
echo "    ninja -C build"
echo "    sudo ninja -C build install"
echo "-----------------------------------------"

echo ""
echo "Installing required fonts..."

FONT_URL="https://github.com/zed-industries/zed-fonts/releases/download/1.2.0/zed-sans-1.2.0.zip"
FONT_DIR="$HOME/.fonts/zed-sans"
TEMP_ZIP="/tmp/zed-sans-1.2.0.zip"

# Check if Zed fonts are already installed
if [ ! -d "$FONT_DIR" ]; then
    echo "Downloading Zed fonts from $FONT_URL..."
    curl -L -o "$TEMP_ZIP" "$FONT_URL"

    echo "Extracting Zed fonts to "$FONT_DIR"..."
    mkdir -p "$FONT_DIR"
    unzip -o "$TEMP_ZIP" -d "$FONT_DIR"

    echo "Cleaning up temporary font file..."
    rm "$TEMP_ZIP"
else
    echo "Zed fonts are already installed. Skipping download and extraction."
fi

# Copy local fonts provided within the Ax-Shell repository
# Assuming these are actual font files (.ttf, .otf) intended for ~/.fonts
LOCAL_FONT_SOURCE_DIR="$INSTALL_DIR/assets/fonts"
LOCAL_FONT_DEST_DIR="$HOME/.fonts/ax-shell-local-fonts" # Use a dedicated directory to avoid conflicts

if [ -d "$LOCAL_FONT_SOURCE_DIR" ] && [ "$(find "$LOCAL_FONT_SOURCE_DIR" -maxdepth 1 -type f -name "*.ttf" -o -name "*.otf" | wc -l)" -gt 0 ]; then
    if [ ! -d "$LOCAL_FONT_DEST_DIR" ] || [ "$(find "$LOCAL_FONT_DEST_DIR" -maxdepth 1 -type f -name "*.ttf" -o -name "*.otf" | wc -l)" -eq 0 ]; then
        echo "Copying local fonts from Ax-Shell to $LOCAL_FONT_DEST_DIR..."
        mkdir -p "$LOCAL_FONT_DEST_DIR"
        cp -r "$LOCAL_FONT_SOURCE_DIR/"* "$LOCAL_FONT_DEST_DIR/"
    else
        echo "Local fonts already appear to be copied. Skipping copy."
    fi
else
    echo "No local fonts found in '$LOCAL_FONT_SOURCE_DIR' or directory does not exist. Skipping local font copy."
fi

echo "Rebuilding font cache to register new fonts..."
fc-cache -fv

python "$INSTALL_DIR/config/config.py"
echo "Attempting to start Ax-Shell..."

# Check if uwsm is installed before attempting to use it
if ! command -v uwsm &>/dev/null; then
    echo "Warning: 'uwsm' command not found. Ax-Shell might not start correctly."
    echo "Please ensure 'uwsm' is installed and in your PATH, possibly by building it from source as described above."
else
    # Attempt to kill any existing Ax-Shell processes
    pkill -f "python $INSTALL_DIR/main.py" 2>/dev/null || true
    # Run Ax-Shell via uwsm, disowning the process
    uwsm app -- python "$INSTALL_DIR/main.py" > /dev/null 2>&1 & disown
fi

echo ""
echo "Installation process complete. Please check the warnings above regarding manual installations."
echo "If Ax-Shell doesn't start, ensure 'uwsm' is correctly installed and in your PATH."
