# USB Network Configuration Utility

This document explains how to configure network settings for your RPi Radio using a USB drive.

## Overview

The USB Network Configuration utility allows you to update network settings by placing a configuration file on a USB drive. This is especially useful for devices installed in locations without keyboards or displays.

## How It Works

1. Format a USB drive (FAT32 is recommended for maximum compatibility)
2. Create a file named `network.json` on the USB drive
3. Insert the USB drive into the RPi Radio
4. The device will automatically detect the USB drive, apply the network settings, and reboot

## Configuration File Format

The `network.json` file uses JSON format and supports both WiFi and static IP configuration:

### WiFi Configuration Example:

```json
{
  "connectionType": "wifi",
  "ssid": "BusinessWiFi",
  "password": "wifi-password-here",
  "hidden": false
}
```

### Static IP Configuration Example:

```json
{
  "connectionType": "static",
  "ipAddress": "192.168.1.100",
  "netmask": "255.255.255.0",
  "gateway": "192.168.1.1",
  "dns1": "8.8.8.8",
  "dns2": "8.8.4.4"
}
```

## Configuration Options

| Option | Description | Required | Default |
|--------|-------------|----------|---------|
| connectionType | Type of connection ("wifi" or "static") | Yes | wifi |
| ssid | WiFi network name | Yes (for WiFi) | - |
| password | WiFi password | No (for open networks) | - |
| hidden | Whether the WiFi network is hidden | No | false |
| ipAddress | Static IP address | Yes (for static) | - |
| netmask | Network mask | No | 255.255.255.0 |
| gateway | Default gateway | Yes (for static) | - |
| dns1 | Primary DNS server | No | 8.8.8.8 |
| dns2 | Secondary DNS server | No | 8.8.4.4 |

## Status and Feedback

After processing your configuration, the system will:

1. Create a `network.status` file on the USB drive with the results
2. Create a `network.lock` file that prevents reconfiguration for 30 minutes
3. Log all actions to the device's system log

## Troubleshooting

If your configuration fails to apply, check the `network.status` file on the USB drive for error messages. Common issues include:

- Invalid JSON format
- Missing required fields
- Incorrect network settings
- USB drive not properly mounted

For more assistance, consult the technical support documentation.