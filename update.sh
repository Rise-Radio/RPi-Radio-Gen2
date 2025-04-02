#!/bin/bash

# RPi Radio - Update Script
# This script updates the application code and restarts services

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
  error "This script must be run as root (sudo ./update.sh)"
fi

# Display welcome message
log "RPi Radio Update Script"
log "======================="
log "This script will update the application code and restart services."
echo ""

# Backup current config
log "Backing up configuration..."
mkdir -p backups
cp -r config backups/config-$(date +"%Y%m%d%H%M%S")

# Pull latest code if in a git repository
if [ -d .git ]; then
  log "Updating code from git repository..."
  git pull
else
  warn "Not a git repository. Manual update required."
fi

# Install any new dependencies
log "Updating npm dependencies..."
npm install

# Update services if they've changed
if [ -d /etc/systemd/system ]; then
  log "Updating systemd services..."
  cp rpi-radio.service /etc/systemd/system/
  cp usb-network-config.service /etc/systemd/system/
  systemctl daemon-reload
fi

# Update udev rules if they've changed
if [ -d /etc/udev/rules.d ]; then
  log "Updating udev rules..."
  cp 99-usb-network-config.rules /etc/udev/rules.d/
  udevadm control --reload-rules
fi

# Make sure scripts are executable
log "Setting correct permissions on scripts..."
chmod +x scripts/*.sh

# Restart services
log "Restarting RPi Radio service..."
systemctl restart rpi-radio.service

log "Update completed successfully!"
log "Web interface: http://$(hostname -I | awk '{print $1}'):3000"