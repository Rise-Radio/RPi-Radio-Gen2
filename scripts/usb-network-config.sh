#!/bin/bash

# USB Network Configuration Utility for RPi Radio
# Checks for a network.json file on mounted USB drives and applies network settings

# Logging setup
LOG_FILE="/var/log/rpi-radio-usb-config.log"
CONFIG_PATH=""
LOCK_DURATION=1800  # 30 minutes in seconds

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
  echo "$1"
}

find_config_file() {
  # Look for network.json in common USB mount points
  for mount in /media/* /mnt/* /run/media/*; do
    if [ -d "$mount" ]; then
      if [ -f "$mount/network.json" ]; then
        CONFIG_PATH="$mount/network.json"
        USB_PATH="$mount"
        log "Found network.json at $CONFIG_PATH"
        return 0
      fi
    fi
  done
  
  log "No network.json found on any mounted USB drives"
  return 1
}

check_lock_file() {
  LOCK_FILE="$USB_PATH/network.lock"
  
  if [ -f "$LOCK_FILE" ]; then
    LOCK_TIME=$(cat "$LOCK_FILE")
    CURRENT_TIME=$(date +%s)
    
    if [ $((CURRENT_TIME - LOCK_TIME)) -lt $LOCK_DURATION ]; then
      log "Lock file is still valid. Skipping network update."
      return 1
    else
      log "Lock file expired. Proceeding with update."
      return 0
    fi
  fi
  
  log "No lock file found. Proceeding with update."
  return 0
}

create_lock_file() {
  LOCK_FILE="$USB_PATH/network.lock"
  date +%s > "$LOCK_FILE"
  log "Created lock file at $LOCK_FILE"
}

write_status_file() {
  STATUS_FILE="$USB_PATH/network.status"
  echo "Timestamp: $(date)" > "$STATUS_FILE"
  echo "Status: $1" >> "$STATUS_FILE"
  echo "Details: $2" >> "$STATUS_FILE"
  log "Wrote status to $STATUS_FILE: $1 - $2"
}

apply_network_config() {
  log "Applying network configuration from $CONFIG_PATH"
  
  # Validate JSON format
  if ! jq . "$CONFIG_PATH" > /dev/null 2>&1; then
    log "Error: Invalid JSON format in network.json"
    write_status_file "ERROR" "Invalid JSON format in network.json"
    return 1
  fi
  
  # Read config values
  CONNECTION_TYPE=$(jq -r '.connectionType // "wifi"' "$CONFIG_PATH")
  
  # Process based on connection type
  if [ "$CONNECTION_TYPE" = "static" ]; then
    apply_static_config
  elif [ "$CONNECTION_TYPE" = "wifi" ]; then
    apply_wifi_config
  else
    log "Error: Unknown connection type: $CONNECTION_TYPE"
    write_status_file "ERROR" "Unknown connection type: $CONNECTION_TYPE"
    return 1
  fi
}

apply_static_config() {
  log "Applying static IP configuration"
  
  # Extract static IP configuration
  IP_ADDRESS=$(jq -r '.ipAddress // ""' "$CONFIG_PATH")
  NETMASK=$(jq -r '.netmask // "255.255.255.0"' "$CONFIG_PATH")
  GATEWAY=$(jq -r '.gateway // ""' "$CONFIG_PATH")
  DNS1=$(jq -r '.dns1 // "8.8.8.8"' "$CONFIG_PATH")
  DNS2=$(jq -r '.dns2 // "8.8.4.4"' "$CONFIG_PATH")
  
  # Validate required fields
  if [ -z "$IP_ADDRESS" ] || [ -z "$GATEWAY" ]; then
    log "Error: Missing required static IP configuration"
    write_status_file "ERROR" "Missing required static IP configuration"
    return 1
  fi
  
  # Create network config file
  cat > /etc/network/interfaces.d/eth0 << EOF
auto eth0
iface eth0 inet static
  address $IP_ADDRESS
  netmask $NETMASK
  gateway $GATEWAY
  dns-nameservers $DNS1 $DNS2
EOF
  
  log "Static IP configuration applied"
  write_status_file "SUCCESS" "Static IP configuration applied: $IP_ADDRESS"
  return 0
}

apply_wifi_config() {
  log "Applying WiFi configuration"
  
  # Extract WiFi configuration
  SSID=$(jq -r '.ssid // ""' "$CONFIG_PATH")
  PASSWORD=$(jq -r '.password // ""' "$CONFIG_PATH")
  HIDDEN=$(jq -r '.hidden // "false"' "$CONFIG_PATH")
  
  # Validate required fields
  if [ -z "$SSID" ]; then
    log "Error: Missing required WiFi SSID"
    write_status_file "ERROR" "Missing required WiFi SSID"
    return 1
  fi
  
  # Create wpa_supplicant configuration
  WIFI_CONF="/etc/wpa_supplicant/wpa_supplicant.conf"
  
  # Create basic configuration
  cat > "$WIFI_CONF" << EOF
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=US

EOF
  
  # Add network configuration
  if [ -n "$PASSWORD" ]; then
    # Configure with password
    wpa_passphrase "$SSID" "$PASSWORD" >> "$WIFI_CONF"
    
    # If hidden network, add scan_ssid=1
    if [ "$HIDDEN" = "true" ]; then
      sed -i '/ssid=/a\\tscan_ssid=1' "$WIFI_CONF"
    fi
  else
    # Open network
    cat >> "$WIFI_CONF" << EOF
network={
  ssid="$SSID"
  key_mgmt=NONE
EOF
    
    # If hidden network, add scan_ssid=1
    if [ "$HIDDEN" = "true" ]; then
      echo "  scan_ssid=1" >> "$WIFI_CONF"
    fi
    
    echo "}" >> "$WIFI_CONF"
  fi
  
  log "WiFi configuration applied for SSID: $SSID"
  write_status_file "SUCCESS" "WiFi configuration applied for SSID: $SSID"
  return 0
}

# Main execution
log "Starting USB Network Configuration Utility"

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    log "Error: This script must be run as root"
    exit 1
fi

# Find the config file
if ! find_config_file; then
    log "Exiting: No configuration file found"
    exit 0
fi

# Check if lock file is valid
if ! check_lock_file; then
    log "Exiting: Lock file is still valid"
    exit 0
fi

# Apply network configuration
if apply_network_config; then
    # Create lock file
    create_lock_file
    
    log "Network configuration applied successfully. Rebooting in 5 seconds..."
    sync
    sleep 5
    reboot
else
    log "Failed to apply network configuration"
fi