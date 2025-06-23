#!/bin/bash

# ==============================================================================
# IMPORTANT: PLEASE READ CAREFULLY BEFORE RUNNING THIS SCRIPT
# ==============================================================================
# If you are still encountering "Failed to enable COPR" errors (e.g., for
# atim/cliphist or ryuuts/hyprland), it means you are NOT running this current
# version of the script. This version has REMOVED ALL problematic COPR calls.
#
# To ensure you run the correct version:
# 1. DELETE any previous copies of this installation script from your system.
# 2. COPY THE ENTIRETY OF THIS CODE BLOCK from the Canvas into a NEW file,
#    for example: `install_quiet_shell.sh`
# 3. Make it executable: `chmod +x install_quiet_shell.sh`
# 4. Run it: `./install_quiet_shell.sh`
#
# This script will install DNF packages and then provide MANUAL
# build instructions for components that do not have stable Fedora 42 packages
# or reliable COPRs yet. You MUST follow these manual steps.
# ==============================================================================

set -e      # Exit immediately if a command fails
set -u      # Treat unset variables as errors
set -o pipefail  # Prevent errors in a pipeline from being masked

REPO_URL="https://github.com/ackerman010/Quiet-Shell.git" # Updated to Quiet-Shell
INSTALL_DIR="$HOME/.config/Quiet-Shell" # Updated to Quiet-Shell

# Get the current Fedora release version dynamically
FEDORA_RELEASE_VERSION=$(rpm -E %fedora)
if [ -z "$FEDORA_RELEASE_VERSION" ]; then
    echo "Error: Could not determine Fedora release version. Please ensure 'rpm -E %fedora' works."
    exit 1
fi
echo "Detected Fedora Release Version: $FEDORA_RELEASE_VERSION"

# DNF packages available in official Fedora repositories
# Removed cliphist, gpu-screen-recorder, and nerd-fonts from here as they will be
# either built from source or handled differently.
DNF_PACKAGES=(
    brightnessctl
    cava
    gnome-bluetooth          # Equivalent to gnome-bluetooth-3.0 (runtime)
    gnome-bluetooth-libs-devel # Development files for gnome-bluetooth
    gobject-introspection
    ImageMagick              # Equivalent to imagemagick
    libnotify
    google-noto-color-emoji-fonts # Equivalent to noto-fonts-emoji (official Fedora package for these)
    nvtop
    playerctl
    python3-fabric           # Equivalent to python-fabric-git, provides stable Fabric
    python3-gobject          # Equivalent to python-gobject
    python3-ijson            # Equivalent to python-ijson
    python3-numpy           # Equivalent to python-numpy
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
    python3-pip             # Added: For installing Python packages via pip
    python3-devel           # Added: For building some Python modules from source
)

# All packages that were previously in COPR_PACKAGES are now in BUILD_FROM_SOURCE_PACKAGES
# as COPRs for Fedora 42 are proving to be unreliable.
COPR_PACKAGES=()

# Packages that are specific to the original Arch setup or less common,
# and need to be built from source or installed manually on Fedora due to
# lack of direct DNF packages or reliable COPRs for Fedora 42.
BUILD_FROM_SOURCE_PACKAGES=(
    hyprland                # Core Hyprland compositor
    hypridle                # Hyprland idle daemon
    hyprlock                # Hyprland screen locker
    hyprpicker              # Hyprland color picker
    hyprshot                # Hyprland screenshot utility
    hyprsunset              # Hyprland feature/utility, potentially part of Hyprland
    swww                    # Wallpaper daemon for Wayland
    cliphist                # Clipboard history manager
    gpu-screen-recorder     # Screen recording utility
    matugen                 # Original: matugen-bin. A Python project.
    gray                    # Original: gray-git. A theme by Axenide.
    uwsm                    # Wayland Session Manager by Axenide, a dependency of Ax-Shell itself.
    nerd-fonts              # Although google-noto-color-emoji-fonts is in DNF, a broader Nerd Font install might be needed.
)

# Prevent running as root for safety
if [ "$(id -u)" -eq 0 ]; then
    echo "Please do not run this script as root."
    exit 1
fi

echo "Updating DNF package cache..."
sudo dnf check-update || true # Allow check-update to fail without stopping script if no updates are available

# No COPR repositories will be enabled automatically due to repeated 404 errors.
# All previously COPR-dependent packages are now expected to be built from source.
echo "Skipping COPR repository enablement due to Fedora 42 availability issues."


# Install required DNF packages only
echo "Installing required DNF packages..."
sudo dnf install -y -q "${DNF_PACKAGES[@]}" || { echo "Warning: Some DNF packages failed to install. Continuing with the script."; }

# Clone or update the Ax-Shell repository
if [ -d "$INSTALL_DIR" ]; then
    echo "Updating Quiet-Shell..."
    git -C "$INSTALL_DIR" pull
else
    echo "Cloning Quiet-Shell..."
    git clone --depth=1 "$REPO_URL" "$INSTALL_DIR"
fi

# --- Manual Installation Instructions ---
echo ""
echo "--- MANUAL INSTALLATION REQUIRED FOR MANY COMPONENTS ---"
echo "Due to current COPR unavailability for Fedora $FEDORA_RELEASE_VERSION, "
echo "many of the required tools need to be built from source or installed manually."

echo ""
echo "First, install common build dependencies for various projects:"
echo "sudo dnf install -y meson ninja-build gcc-c++ pkg-config wayland-devel wayland-protocols-devel \
                       libinput-devel libxkbcommon-devel pixman-devel pango-devel cairo-devel \
                       systemd-devel seatd-devel polkit-devel xdg-desktop-portal-devel libdisplay-info-devel \
                       libdrm-devel systemd-libs-devel ncurses-devel libevdev-devel upower-devel \
                       rust cargo # For Rust-based projects like swww, cliphist, gpu-screen-recorder"
echo "sudo dnf install -y go # For Go-based projects like cliphist"
echo "sudo dnf install -y # Ensure Python build dependencies if any Python packages need compilation (e.g., python3-devel)"

echo ""
echo "--- Specific Build Instructions for Key Components: ---"

echo ""
echo "- **Python Dependencies (e.g., 'fabric'):**"
echo "  Many Python projects rely on `pip` for their dependencies. Since 'fabric' was specifically missing:"
echo "  pip install fabric # Install the Python 'fabric' library"
echo "  # If you encounter other Python module errors, try 'pip install <missing-module-name>'"

echo ""
echo "- Hyprland and its related tools (hypridle, hyprlock, hyprpicker, hyprshot, hyprsunset):"
echo "  All of these are typically built from the Hyprland source. Follow the official Hyprland wiki for detailed build instructions."
echo "  Official Hyprland Wiki: https://wiki.hyprland.org/Getting-Started/Installing-Hyprland/"
echo "  Basic steps (may vary depending on official instructions):"
echo "    git clone --recursive https://github.com/hyprwm/Hyprland.git ~/Hyprland-source"
echo "    cd ~/Hyprland-source"
echo "    meson build --prefix /usr"
echo "    ninja -C build"
echo "    sudo ninja -C build install"
echo "  Note: The utilities (hypridle, hyprlock, hyprpicker, hyprshot) are often compiled automatically as part of the Hyprland build or have their own sub-projects within the Hyprland repository. Refer to the wiki for specifics."

echo ""
echo "- swww (Wallpaper daemon):"
echo "  This is a Rust-based project. Check its GitHub page for specific build dependencies and instructions."
echo "  GitHub: https://github.com/Horus645/swww"
echo "  Example basic build steps (may vary):"
echo "    git clone https://github.com/Horus645/swww.git ~/swww-source"
echo "    cd ~/swww-source"
echo "    cargo build --release"
echo "    sudo install -Dm755 target/release/swww /usr/local/bin/swww"

echo ""
echo "- cliphist (Clipboard history manager):"
echo "  This is a Go-based project. Check its GitHub page for specific build dependencies and instructions."
echo "  GitHub: https://github.com/sentriz/cliphist"
echo "  Example basic build steps (may vary):"
echo "    git clone https://github.com/sentriz/cliphist.git ~/cliphist-source"
echo "    cd ~/cliphist-source"
echo "    go build -o cliphist"
echo "    sudo install -Dm755 cliphist /usr/local/bin/cliphist"

echo ""
echo "- gpu-screen-recorder:"
echo "  This is also a Go-based project. Check its GitHub page for specific build dependencies and instructions."
echo "  GitHub: https://github.com/russelltg/gpu-screen-recorder"
echo "  Example basic build steps (may vary):"
echo "    git clone https://github.com/russelltg/gpu-screen-recorder.git ~/gpu-screen-recorder-source"
echo "    cd ~/gpu-screen-recorder-source"
echo "    go build -o gpu-screen-recorder"
echo "    sudo install -Dm755 gpu-screen-recorder /usr/local/bin/gpu-screen-recorder"

echo ""
echo "- matugen (Original: matugen-bin): This is a Python-based utility."
echo "  To install via pip (recommended if available):"
echo "    pip install matugen"
echo "  Or, to clone and use:"
echo "    git clone https://github.com/material-foundation/matugen.git ~/matugen-source"
echo "    # Follow matugen's specific installation/usage instructions."

echo ""
echo "- gray (Original: gray-git): This appears to be a theme or utility specific to Axenide's projects."
echo "  Please refer to its GitHub repository for installation instructions, or manually place its files."
echo "  GitHub: https://github.com/Axenide/gray"

echo ""
echo "- uwsm (Wayland Session Manager): This is a critical dependency for Ax-Shell and likely needs to be built from source."
echo "  Please refer to its GitHub repository for detailed build instructions:"
echo "  GitHub: https://github.com/Axenide/uwsm"
echo "  Example basic build steps (may vary):"
echo "    git clone https://github.com/Axenide/uwsm.git ~/uwsm-source"
echo "    cd ~/uwsm-source"
echo "    meson build"
echo "    ninja -C build"
echo "    sudo ninja -C build install"

echo ""
echo "- Nerd Fonts:"
echo "  If the 'google-noto-color-emoji-fonts' package from DNF is not sufficient, you might need to install more comprehensive Nerd Fonts."
echo "  You can download them manually from their GitHub releases page and extract them to ~/.fonts, then run 'fc-cache -fv'."
echo "  GitHub: https://github.com/ryanoasis/nerd-fonts/releases"

echo "-----------------------------------------"

echo ""
echo "Installing required fonts from Zed Industries..."

FONT_URL="https://github.com/zed-industries/zed-fonts/releases/download/1.2.0/zed-sans-1.2.0.zip"
FONT_DIR="$HOME/.fonts/zed-sans"
TEMP_ZIP="/tmp/zed-sans-1.2.0.zip"

# Check if Zed fonts are already installed
if [ ! -d "$FONT_DIR" ]; then
    echo "Downloading Zed fonts from "$FONT_URL"..."
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
echo "Installation process complete. Please ensure you have manually built and installed the necessary components listed above."
echo "If Ax-Shell doesn't start, double-check all manual installation steps."
