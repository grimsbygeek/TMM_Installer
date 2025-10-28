#!/bin/bash

# Tiny Media Manager installation script
set -e

# Configuration
TMM_VERSION="5.2.3"
ARCH_VERSION="amd64"
INSTALL_DIR="/opt/tinyMediaManager"
DESKTOP_FILE="/usr/share/applications/tinyMediaManager.desktop"
DOWNLOAD_URL="https://archive.tinymediamanager.org/v${TMM_VERSION}/tinyMediaManager-${TMM_VERSION}-linux-${ARCH_VERSION}.tar.xz"
TEMP_DIR=$(mktemp -d)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
echo "${DOWNLOAD_URL}"
# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check for curl
if ! command -v curl &> /dev/null; then
    print_error "curl is required but not installed. Please install it first:"
    echo "  Ubuntu/Debian: sudo apt install curl"
    echo "  Fedora/RHEL: sudo dnf install curl"
    echo "  Arch: sudo pacman -S curl"
    exit 1
fi

# Check for tar with xz support
if ! command -v tar &> /dev/null; then
    print_error "tar is required but not installed. Please install it first:"
    echo "  Ubuntu/Debian: sudo apt install tar"
    echo "  Fedora/RHEL: sudo dnf install tar"
    echo "  Arch: sudo pacman -S tar"
    exit 1
fi

# Check if tar supports xz compression
if ! tar --help | grep -q "xz"; then
    print_error "Your tar version doesn't support xz compression."
    print_error "Please install xz-utils:"
    echo "  Ubuntu/Debian: sudo apt install xz-utils"
    echo "  Fedora/RHEL: sudo dnf install xz"
    echo "  Arch: sudo pacman -S xz"
    exit 1
fi

print_status "Starting Tiny Media Manager installation..."
print_status "Version: ${TMM_VERSION}"
print_status "Install directory: ${INSTALL_DIR}"
print_status "Download URL: ${DOWNLOAD_URL}"

# Create installation directory with sudo
print_status "Creating installation directory..."
sudo mkdir -p "$INSTALL_DIR"

# Download Tiny Media Manager using curl
print_status "Downloading Tiny Media Manager..."
cd "$TEMP_DIR"
curl -L --progress-bar "$DOWNLOAD_URL" -o "tinyMediaManager-${TMM_VERSION}-linux-${ARCH_VERSION}.tar.xz"

# Check if download was successful
if [ ! -f "tinyMediaManager-${TMM_VERSION}-linux-${ARCH_VERSION}.tar.xz" ]; then
    print_error "Download failed! File not found."
    exit 1
fi

# Check file size to ensure download completed
FILE_SIZE=$(stat -c%s "tinyMediaManager-${TMM_VERSION}-linux-${ARCH_VERSION}.tar.xz" 2>/dev/null || stat -f%z "tinyMediaManager-${TMM_VERSION}.tar.xz")
if [ "$FILE_SIZE" -lt 1000000 ]; then  # Less than 1MB likely means error
    print_error "Download seems incomplete or failed (file too small: ${FILE_SIZE} bytes)"
    exit 1
fi

print_status "Download completed (${FILE_SIZE} bytes)"

# Extract the .tar.xz archive (needs sudo for /opt)
print_status "Extracting .tar.xz file to $INSTALL_DIR..."
sudo tar -xJf "tinyMediaManager-${TMM_VERSION}-linux-${ARCH_VERSION}.tar.xz" -C "$INSTALL_DIR" --strip-components=1

# Check if extraction was successful
if [ $? -ne 0 ]; then
    print_error "Extraction failed!"
    print_error "This might be due to:"
    print_error "1. Corrupted download - try running the script again"
    print_error "2. Missing xz support - ensure xz-utils is installed"
    print_error "3. Insufficient disk space"
    exit 1
fi

print_status "Extraction completed successfully"

# Make all scripts executable for all users
print_status "Setting executable permissions for all users..."
sudo find "$INSTALL_DIR" -name "*.sh" -type f -exec chmod 755 {} \; 2>/dev/null || true
sudo find "$INSTALL_DIR" -name "tmm" -type f -exec chmod 755 {} \; 2>/dev/null || true
sudo find "$INSTALL_DIR" -name "tinyMediaManager" -type f -exec chmod 755 {} \; 2>/dev/null || true

# Find the main executable
MAIN_EXEC=""
if [[ -f "$INSTALL_DIR/tinyMediaManager" ]]; then
    MAIN_EXEC="$INSTALL_DIR/tinyMediaManager"
elif [[ -f "$INSTALL_DIR/tmm" ]]; then
    MAIN_EXEC="$INSTALL_DIR/tmm"
else
    # Try to find any executable file
    MAIN_EXEC=$(sudo find "$INSTALL_DIR" -type f -executable -name "tmm*" -o -name "tinyMediaManager*" | head -1)
    if [[ -z "$MAIN_EXEC" ]]; then
        print_warning "No clear main executable found. Listing contents of installation directory:"
        sudo ls -la "$INSTALL_DIR"
        print_warning "You may need to manually run the appropriate script from: $INSTALL_DIR"
    fi
fi

# Set proper ownership and permissions for the entire installation
print_status "Setting directory permissions for multi-user access..."
sudo chown -R root:root "$INSTALL_DIR"
sudo chmod -R 755 "$INSTALL_DIR"
sudo chmod -R a+X "$INSTALL_DIR"  # Ensure execute permission for all users

# Create desktop entry for all users
print_status "Creating desktop shortcut for all users..."
cat << EOF | sudo tee "$DESKTOP_FILE" > /dev/null
[Desktop Entry]
Version=1.0
Type=Application
Name=Tiny Media Manager
Comment=Manage your media files
Exec=$INSTALL_DIR/tinyMediaManager
Icon=video-player
Categories=AudioVideo;Video;
Terminal=false
StartupWMClass=tinyMediaManager
EOF

# Try to find and use the actual icon
ICON_FOUND=false
if sudo test -f "$INSTALL_DIR/tmm.png"; then
    sudo sed -i "s|Icon=video-player|Icon=$INSTALL_DIR/tmm.png|" "$DESKTOP_FILE"
    print_status "Using custom icon: $INSTALL_DIR/tmm.png"
    ICON_FOUND=true
else
    # Search for any image file that could be an icon
    ICON_FILE=$(sudo find "$INSTALL_DIR" \( -name "*.png" -o -name "*.svg" -o -name "*.xpm" \) -type f | head -1)
    if [[ -n "$ICON_FILE" ]]; then
        sudo sed -i "s|Icon=video-player|Icon=$ICON_FILE|" "$DESKTOP_FILE"
        print_status "Using icon: $ICON_FILE"
        ICON_FOUND=true
    fi
fi

# Update the Exec line with the actual main executable if found
if [[ -n "$MAIN_EXEC" ]]; then
    sudo sed -i "s|Exec=$INSTALL_DIR/tinyMediaManager|Exec=$MAIN_EXEC|" "$DESKTOP_FILE"
    print_status "Main executable: $MAIN_EXEC"
fi

# Make desktop file readable by all
sudo chmod 644 "$DESKTOP_FILE"

# Update desktop database
print_status "Updating desktop database..."
sudo update-desktop-database /usr/share/applications 2>/dev/null || true

# Create a symlink in /usr/local/bin for easy command line access for all users
if [[ -n "$MAIN_EXEC" ]]; then
    print_status "Creating symlink in /usr/local/bin for all users..."
    sudo ln -sf "$MAIN_EXEC" /usr/local/bin/tinyMediaManager
    # Ensure the symlink target is executable by all
    sudo chmod 755 "$MAIN_EXEC" 2>/dev/null || true
fi

# Create a wrapper script to ensure proper execution by any user
WRAPPER_SCRIPT="/usr/local/bin/tmm"
print_status "Creating wrapper script for better multi-user support..."
sudo tee "$WRAPPER_SCRIPT" > /dev/null << 'EOF'
#!/bin/bash
# Wrapper script for Tiny Media Manager - ensures any user can run it

TMM_DIR="/opt/tinyMediaManager"

# Find the main executable
if [[ -f "$TMM_DIR/tinyMediaManager" ]]; then
    exec "$TMM_DIR/tinyMediaManager" "$@"
elif [[ -f "$TMM_DIR/tmm" ]]; then
    exec "$TMM_DIR/tmm" "$@"
else
    echo "Error: Could not find Tiny Media Manager executable in $TMM_DIR"
    echo "Available files:"
    ls -la "$TMM_DIR" 2>/dev/null | head -10
    exit 1
fi
EOF

sudo chmod 755 "$WRAPPER_SCRIPT"

# Clean up
print_status "Cleaning up temporary files..."
rm -rf "$TEMP_DIR"

print_status "${GREEN}Installation completed successfully!${NC}"
echo
print_status "Tiny Media Manager has been installed to: $INSTALL_DIR"
print_status "All users on the system can now:"
print_status "  - Launch from application menu (Audio & Video category)"
print_status "  - Run from terminal: tinyMediaManager"
print_status "  - Run from terminal: tmm"
echo

# List the installed files for verification
print_status "Installed files:"
sudo ls -la "$INSTALL_DIR" | head -10

# Check if Java is installed (required for tmm)
print_status "Checking for Java runtime..."
if ! command -v java &> /dev/null; then
    print_warning "Java is not installed. Tiny Media Manager requires Java 11 or later."
    print_warning "Please install Java using your package manager:"
    echo "  Ubuntu/Debian: sudo apt install openjdk-17-jre"
    echo "  Fedora/RHEL: sudo dnf install java-17-openjdk"
    echo "  Arch: sudo pacman -S jre17-openjdk"
    echo "  openSUSE: sudo zypper install java-17-openjdk"
else
    JAVA_VERSION=$(java -version 2>&1 | head -1 | cut -d'"' -f2)
    print_status "Java version detected: $JAVA_VERSION"
fi

# Test if the application can be found
print_status "Testing installation..."
if command -v tinyMediaManager &> /dev/null || command -v tmm &> /dev/null; then
    print_status "Installation verified - commands are available in PATH"
else
    print_warning "Commands not found in PATH, but application is installed at: $INSTALL_DIR"
fi

echo
print_status "Installation complete! You can now run 'tinyMediaManager' or 'tmm' from any terminal,"
print_status "or find 'Tiny Media Manager' in your application menu."