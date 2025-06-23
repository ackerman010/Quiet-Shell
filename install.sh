#!/usr/bin/env bash
# install.sh — Automated Ax-Shell installer for Fedora 42
set -euo pipefail

# Timestamp for backups
TS=$(date +"%Y%m%d-%H%M%S")

# --- GLOBAL PKG_CONFIG_PATH SETUP ---
# Prioritize /usr/local/lib/pkgconfig for source-built libraries
# Use :- to initialize if PKG_CONFIG_PATH is not already set, preventing unbound variable error
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
echo "Global PKG_CONFIG_PATH set to: $PKG_CONFIG_PATH"

# Repository details for Ax-Shell
REPO_URL="https://github.com/Axenide/Ax-Shell.git"
INSTALL_DIR="$HOME/.config/Ax-Shell"

# --- Helper Functions ---
# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to clean up a temporary directory
cleanup_temp_dir() {
    local dir="$1"
    if [ -d "$dir" ]; then
        echo "Cleaning up temporary directory: $dir"
        sudo rm -rf "$dir"
    fi
}

# --- Main Script Execution ---

# Prevent running as root
if [ "$(id -u)" -eq 0 ]; then
    echo "Error: Please do not run this script as root. Run it as a regular user using 'bash ./install.sh'."
    exit 1
fi

# 1. Clone or update the Ax-Shell repository
echo "[1/10] Cloning or updating Ax-Shell repository..."
if [ -d "$INSTALL_DIR" ]; then
    echo "  - Updating existing Ax-Shell installation..."
    git -C "$INSTALL_DIR" pull || { echo "Warning: Failed to pull latest changes for Ax-Shell. Continuing with existing files."; }
else
    echo "  - Cloning Ax-Shell from $REPO_URL to $INSTALL_DIR..."
    git clone --depth=1 "$REPO_URL" "$INSTALL_DIR" || { echo "Error: Failed to clone Ax-Shell repository. Exiting."; exit 1; }
fi
echo "Ax-Shell repository setup complete."


# 2. System update and enable COPRs
echo "[2/10] Updating system and enabling necessary COPR repositories..."
sudo dnf upgrade -y

# Enable COPRs
echo "  - Ensuring necessary COPR repositories are enabled:"
# Hyprland COPR for core components
if ! sudo dnf copr enable -y "solopasha/hyprland"; then
    echo "Error: Failed to enable COPR repository 'solopasha/hyprland'. Please check the COPR name or internet connection."
    exit 1 # Exit if this critical COPR cannot be enabled
fi
# Nerd Fonts COPR
if ! sudo dnf copr enable -y "che/nerd-fonts"; then
    echo "⚠️ Warning: COPR enable failed for 'che/nerd-fonts', proceeding without it. Nerd Fonts might need manual install."
fi
echo "COPR repositories enabled."


# 3. Proactive Removal of potentially conflicting older versions
echo "[3/10] Proactively removing conflicting DNF packages (if any) to ensure clean install from COPR/repos..."
# List all packages that will be installed from COPRs or might cause conflicts
CONFLICT_PKGS=(
    hyprlang hyprutils hyprgraphics hyprpaper mpvpaper swaync wlogout
    hypridle hyprlock hyprpicker hyprshot hyprsunset
    # Other packages that might cause conflicts if old versions are present
    # Add more here if you encounter persistent version conflicts
)
for pkg in "${CONFLICT_PKGS[@]}"; do
    if sudo dnf list installed "$pkg" &>/dev/null; then
        echo "  - Removing conflicting DNF package: $pkg"
        sudo dnf remove -y "$pkg" || true # Use || true to prevent script exit if removal fails for non-critical reasons
    else
        echo "  - Conflicting DNF package $pkg not found, skipping removal."
    fi
done
echo "Attempted to remove conflicting packages."


# 4. Install system packages from Fedora repositories (dnf) and COPRs
echo "[4/10] Installing core system packages and Hyprland components via DNF and COPRs..."
sudo dnf install -y \
    git curl unzip cargo pkgconfig \
    cmake make gcc-c++ \
    wayland-devel lz4-devel wayland-protocols-devel \
    libpng-devel cairo-devel gdk-pixbuf2-devel \
    file-devel \
    libei-devel libinput-devel \
    gtk3 gtk2 libnotify gsettings-desktop-schemas \
    fontconfig \
    dnf-plugins-core \
    ImageMagick \
    brightnessctl cava cliphist \
    gnome-bluetooth-devel # for gnome-bluetooth-3.0 development files
    # gobject-introspection and python3-gobject are base system for python3-gobject package
    gpu-screen-recorder # From solopasha/hyprland COPR
    grim slurp # For grimblast
    hypridle hyprlock hyprpicker hyprshot hyprsunset # From solopasha/hyprland COPR
    nvtop playerctl tesseract tmux upower vte-devel \
    wl-clipboard wlogout wlinhibit # wlinhibit might need COPR or source, adding to dnf first
    webp-pixbuf-loader # Might be in COPR, adding to dnf first
    python3-gobject python3-numpy python3-pillow python3-psutil python3-requests python3-fabric \
    python3-pip # Ensure pip is installed for later Python dependencies
    mpv thunar thunar-archive-plugin mate-polkit \
    sddm swayidle swaylock dmenu \
    hyprland hyprpaper hyprlang hyprutils hyprgraphics \
    mpvpaper swaync \
    nerd-fonts # Base nerd fonts package
    nerd-fonts-complete || \
    { echo "Error: One or more DNF packages could not be installed. Please check the output above for missing packages or COPR issues."; exit 1; }
echo "All system and COPR packages installed."


# 5. Install remaining Python dependencies via pip
echo "[5/10] Installing additional Python dependencies via pip..."
PYTHON_PIP_PACKAGES=(
    "ijson"
    "pywayland"
    "setproctitle"
    "toml"
    "watchdog"
    "matugen" # matugen-bin from AUR is `matugen` from pip
)
PIP_REQUIREMENTS_FILE="/tmp/pip_requirements.txt"
printf "%s\n" "${PYTHON_PIP_PACKAGES[@]}" > "$PIP_REQUIREMENTS_FILE"

pip3 install --user -r "$PIP_REQUIREMENTS_FILE" || { echo "Warning: Some Python packages could not be installed via pip. Manual check might be needed."; }
rm -f "$PIP_REQUIREMENTS_FILE"
echo "Python dependencies installed."


# 6. Install swww wallpaper daemon from source (if not in COPR/repos)
echo "[6/10] Installing swww wallpaper daemon from source..."
# swww is generally not in common Fedora Hyprland COPRs, so keeping source build for it.
if ! command_exists swww; then
    build_and_install_rust_project "https://github.com/LGFae/swww.git" "/tmp/swww" "swww"
else
    echo "swww already installed (likely from source), skipping source build."
fi


# 7. Install custom Fonts
echo "[7/10] Installing custom fonts (Zed Sans and Tabler Icons)..."
# Zed Sans Font
FONT_URL="https://github.com/zed-industries/zed-fonts/releases/download/1.2.0/zed-sans-1.2.0.zip"
FONT_DIR="$HOME/.fonts/zed-sans"
TEMP_ZIP="/tmp/zed-sans-1.2.0.zip"

if [ ! -d "$FONT_DIR" ]; then
    echo "  - Downloading Zed Sans fonts from $FONT_URL..."
    curl -L -o "$TEMP_ZIP" "$FONT_URL" || { echo "Error: Failed to download Zed Sans fonts."; exit 1; }

    echo "  - Extracting Zed Sans fonts to $FONT_DIR..."
    mkdir -p "$FONT_DIR"
    unzip -o "$TEMP_ZIP" -d "$FONT_DIR" || { echo "Error: Failed to extract Zed Sans fonts."; exit 1; }

    echo "  - Cleaning up temporary Zed Sans font zip..."
    rm "$TEMP_ZIP"
else
    echo "  - Zed Sans Fonts are already installed. Skipping download and extraction."
fi
echo "Zed Sans Font installation complete."

# Tabler Icons Font (from Ax-Shell assets)
if [ ! -d "$HOME/.fonts/tabler-icons" ]; then
    echo "  - Copying local Tabler Icons fonts to $HOME/.fonts/tabler-icons..."
    mkdir -p "$HOME/.fonts/tabler-icons"
    cp -r "$INSTALL_DIR/assets/fonts/"* "$HOME/.fonts" || { echo "Warning: Failed to copy Tabler Icons fonts. Ensure '$INSTALL_DIR/assets/fonts/' exists and contains fonts."; }
else
    echo "  - Local Tabler Icons fonts are already installed. Skipping copy."
fi
echo "Tabler Icons Font installation complete."

# Update font cache for all new fonts
echo "  - Updating font cache for all installed fonts..."
fc-cache -fv || echo "Warning: Failed to update font cache. Font issues might occur."


# 8. Install Icon & GTK themes
echo "[8/10] Installing Tela Circle Dracula and Catppuccin themes..."
cleanup_temp_dir "/tmp/tela" # Ensure clean slate before cloning
git clone --depth 1 https://github.com/vinceliuice/Tela-circle-icon-theme.git /tmp/tela
if [ $? -ne 0 ]; then
    echo "Error: Failed to clone Tela Circle Icon Theme repository."
    exit 1
fi
if [ ! -d "/tmp/tela" ]; then
    echo "Error: Cloned Tela Circle Icon Theme directory /tmp/tela does not exist."
    exit 1
fi

cd /tmp/tela
if [ -f "./install.sh" ]; then
    chmod +x ./install.sh
    echo "  - Running Tela Circle Icon Theme install script..."
    ./install.sh -a
else
    echo "Error: Tela Circle Icon Theme install.sh not found. Attempting manual copy (may not be complete)."
    find . -maxdepth 2 -type d -name "Tela-circle-dracula*" -exec sudo cp -r {} /usr/share/icons/ \; || { echo "Error: Failed to manually copy Tela-circle-dracula theme."; }
    sudo gtk-update-icon-cache -f -t /usr/share/icons/ || { echo "Warning: Failed to update GTK icon cache for Tela theme."; }
fi
cd - > /dev/null # Return to previous directory silently
echo "Tela Circle Dracula Icons installed."

cleanup_temp_dir "/tmp/catppuccin" # Ensure clean slate before cloning
git clone --depth 1 https://github.com/catppuccin/gtk.git /tmp/catppuccin
if [ $? -ne 0 ]; then
    echo "Error: Failed to clone Catppuccin GTK Theme repository."
    exit 1
fi
if [ ! -d "/tmp/catppuccin" ]; then
    echo "Error: Cloned Catppuccin GTK Theme directory /tmp/catppuccin does not exist."
    exit 1
fi

cd /tmp/catppuccin
# Check if install.sh exists and make it executable before running
if [ -f "./install.sh" ]; then
    chmod +x "./install.sh"
    echo "  - Running Catppuccin GTK Theme install script (Mocha)..."
    ./install.sh mocha
else
    echo "Error: Catppuccin GTK Theme install.sh not found. Attempting manual copy (may not be complete)."
    find . -maxdepth 2 -type d -name "Catppuccin-Mocha*" -exec sudo cp -r {} /usr/share/themes/ \; || { echo "Error: Failed to manually copy Catppuccin-Mocha theme."; }
fi
cd - > /dev/null # Return to previous directory silently
echo "Catppuccin GTK theme installed."

# Apply themes
echo "  - Applying GTK and Icon themes system-wide..."
gsettings set org.gnome.desktop.interface icon-theme "Tela-circle-dracula"
gsettings set org.gnome.desktop.interface gtk-theme "Catppuccin-Mocha"
echo "Themes applied."


# 9. File manager cleanup and default
echo "[9/10] Removing other file managers and setting Thunar as default..."
sudo dnf remove -y dolphin nautilus nemo pantheon-files || true
xdg-mime default Thunar.desktop inode/directory application/x-zerosize
echo "Thunar set as default file manager."


# 10. Final Ax-Shell configuration and SDDM activation
echo "[10/10] Completing Ax-Shell setup and enabling SDDM..."

# Ax-Shell specific configuration script execution
echo "  - Running Ax-Shell's config.py script..."
python3 "$INSTALL_DIR/config/config.py" || { echo "Warning: Ax-Shell config.py script failed. Ax-Shell might not function correctly."; }

# Start Ax-Shell (uwsm integration)
echo "  - Starting Ax-Shell (if not already running)..."
killall ax-shell 2>/dev/null || true # Kill existing instances
uwsm app -- python3 "$INSTALL_DIR/main.py" > /dev/null 2>&1 & disown
echo "  - Ax-Shell launched in the background."

# Enable and start SDDM
echo "  - Enabling and starting SDDM display manager..."
# Ensure sddm is installed (it's in step 4, but this is a final check)
if ! command_exists sddm; then
    sudo dnf install -y sddm || { echo "Error: sddm could not be installed, please check DNF."; exit 1; }
fi
# Disable any other active display managers that might conflict
echo "    - Checking for and disabling conflicting display managers..."
for dm_service in gdm lightdm xdm; do
    if systemctl is-enabled "$dm_service" &>/dev/null; then
        echo "      - Disabling conflicting display manager: $dm_service"
        sudo systemctl disable "$dm_service" || true
    fi
done
sudo systemctl daemon-reload
sudo systemctl enable sddm
sudo systemctl start sddm # Use start explicitly
sudo systemctl set-default graphical.target
echo "  - SDDM enabled and started. Check 'systemctl status sddm' if issues persist after reboot."

# Cleanup temporary folders
echo "--- Cleaning up temporary build directories ---"
cleanup_temp_dir "/tmp/swww"
cleanup_temp_dir "/tmp/tela"
cleanup_temp_dir "/tmp/catppuccin"
# Remove temp files created during font download
rm -f "$TEMP_ZIP"
echo "Temporary directories cleaned up."

echo -e "\n✅ Ax-Shell and Hyprland environment installed successfully on Fedora 42!\n"
echo "------------------------------------------------------------"
echo "IMPORTANT NEXT STEPS:"
echo "1. Reboot your system: 'sudo reboot'"
echo "2. After reboot, select 'Hyprland' session from SDDM."
echo "3. Verify Ax-Shell is running and configured by checking its logs or functionality."
echo "4. You might need to adjust GTK theme variants via 'gsettings set org.gnome.desktop.interface gtk-theme <variant>' or a GUI tool if you prefer a different Catppuccin flavor."
echo "5. To update your Ax-Shell dotfiles and reinstall packages (e.g., after pulling changes to your local repo):"
echo "   cd $INSTALL_DIR && git pull origin main && bash ./install.sh" # Assuming 'main' is your default branch for Ax-Shell
echo "Enjoy your new Ax-Shell environment on Fedora 42!"
