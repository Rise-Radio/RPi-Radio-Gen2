#!/bin/bash

# RPi Radio - Installation Script
# This script installs all dependencies and sets up the RPi Radio service

# Exit on any error
set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
log() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
  echo -e "${RED}[ERROR]${NC} $1"
  exit 1
}

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
  error "This script must be run as root (sudo ./install.sh)"
fi

# Display welcome message
log "RPi Radio Installation Script"
log "============================"
log "This script will install all necessary dependencies and configure your Raspberry Pi"
log "as a radio streaming device. Make sure your Pi is connected to the internet."
echo ""

# Check OS
if [ ! -f /etc/os-release ]; then
  error "Cannot determine OS type. This script is designed for Raspberry Pi OS / Alpine Linux."
fi

# Detect Linux distribution
source /etc/os-release
log "Detected: $PRETTY_NAME"

# Check if we're on Alpine or Debian-based
if echo "$ID" | grep -q "alpine"; then
  PKG_MANAGER="apk"
  PKG_UPDATE="apk update"
  PKG_INSTALL="apk add --no-cache"
  NODEJS_PKG="nodejs npm"
  PLAYER_PKG="mpv"
  TOOLS_PKG="jq bash util-linux"
elif echo "$ID" | grep -q -E "debian|raspbian|ubuntu"; then
  PKG_MANAGER="apt"
  PKG_UPDATE="apt-get update"
  PKG_INSTALL="apt-get install -y"
  NODEJS_PKG="nodejs npm"
  PLAYER_PKG="mpv"
  TOOLS_PKG="jq"
else
  warn "Unsupported distribution: $ID. Will attempt to proceed but may encounter issues."
fi

# Update package lists
log "Updating package lists..."
$PKG_UPDATE

# Install Node.js if not present
if ! command -v node &> /dev/null; then
  log "Installing Node.js and npm..."
  $PKG_INSTALL $NODEJS_PKG
else
  log "Node.js already installed: $(node -v)"
fi

# Install MPV player
log "Installing MPV media player..."
$PKG_INSTALL $PLAYER_PKG

# Install additional tools
log "Installing additional tools (jq, etc.)..."
$PKG_INSTALL $TOOLS_PKG

# Create log directory if it doesn't exist
log "Creating log directory..."
mkdir -p logs

# Install npm dependencies
log "Installing npm dependencies..."
npm install

# Set up systemd services
if [ -d /etc/systemd/system ]; then
  log "Setting up systemd services..."
  
  # Copy service files
  cp rpi-radio.service /etc/systemd/system/
  cp usb-network-config.service /etc/systemd/system/
  
  # Reload systemd
  systemctl daemon-reload
  
  # Enable services
  systemctl enable rpi-radio.service
  systemctl enable usb-network-config.service
  
  log "Services installed and enabled!"
else
  warn "Systemd not detected. Services will need to be configured manually."
fi

# Install udev rules for USB network configuration
if [ -d /etc/udev/rules.d ]; then
  log "Installing udev rules for USB network configuration..."
  cp 99-usb-network-config.rules /etc/udev/rules.d/
  udevadm control --reload-rules
fi

# Make scripts executable
log "Setting correct permissions on scripts..."
chmod +x scripts/*.sh

# Set up audio (for Raspberry Pi)
if [ -f /usr/bin/amixer ]; then
  log "Configuring audio..."
  # Set the volume to default (from config)
  VOLUME=$(jq -r '.audioSettings.volume // 80' config/default.json)
  amixer sset Master ${VOLUME}%
fi

# Create necessary log files
log "Creating log files..."
touch /var/log/rpi-radio-usb-config.log
chown root:root /var/log/rpi-radio-usb-config.log

log "Installation completed successfully!"
log "You can now start the service with: sudo systemctl start rpi-radio.service"

# Ask to start service now
read -p "Would you like to start the RPi Radio service now? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  log "Starting RPi Radio service..."
  systemctl start rpi-radio.service
  log "Service started! The web interface is available at: http://$(hostname -I | awk '{print $1}'):3000"
  log "Default login credentials: admin / changeme"
  log "Please change the default password in config/default.json"
fi