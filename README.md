## Overview
This project involves creating a streaming media player using a Raspberry Pi 3B for use in businesses to stream a B2B internet radio station. The device will be running Alpine Linux and will be designed for reliability in commercial environments operated by non-technical users.

## Technical Specifications
- **Hardware**: Raspberry Pi 3B
- **Operating System**: Alpine Linux
- **Audio**: 3.5mm audio jack, single output
- **Stream Format**: MP3 encoded at 64kbps/mono/16bit/44.1kHz
- **Network Protocols**: HTTP and HTTPS for streaming
- **Power**: Standard 2.5A power supply
- **Performance Target**: Boot and begin playback within 30 seconds (excluding update installations)

## Core Features
1. **Remote Code Update Function**
   - Device will check for updates on boot
   - Update server implementation to be developed later

2. **USB Network Configuration Utility**
   - Device will check for network updates from USB configuration file on boot
   - Allows for offline configuration changes

3. **Self-hosted Dashboard**
   - Built with Node.js
   - Controls for:
     - Volume adjustment
     - Restart functionality
     - Update triggering
     - Stream start/stop
     - WiFi setup
     - Static IP assignment

4. **Streaming Function**
   - Automatically starts playing pre-programmed station on boot
   - Customizable stream endpoint (www.myradiostation.com/mountpoint)
   - Robust error handling for network interruptions

## Setup & Deployment
- Initial setup performed by technicians from the B2B radio company
- Setup process includes:
  - Setting device hostname (following standardized format)
  - Configuring customer's IP and/or WiFi information
  - Setting stream endpoint with variable mountpoint
- Factory reset functionality available via SSH only
- Documentation will be created throughout development

## Security & Network
- Basic authentication for dashboard access
- Primarily designed for local area network access
- Future iterations may require enhanced authentication for remote API calls

## Maintenance & Reliability
- No physical controls on the device
- Self-managing logs that delete after a set duration
- Optional scheduled reboot between midnight and 4am to improve long-term stability
- System design to prioritize:
  - Extended lifespan of Pi and SD card
  - Maintaining safe operating temperatures
  - Target device lifecycle of 2-3 years
- Comprehensive error handling for:
  - Power cycling
  - Unstable internet connections
  - Other commercial environment challenges

## Development Environment
- Development on Linode server running Alpine Linux
- Docker containerization
- Version control via GitHub
- Testing process: GitHub → Raspberry Pi test environment

## Update Management
- Updates typically deployed in phases
- Occasional all-at-once deployments as needed
- Rollback functionality to be considered for future iterations

## Future Integration
- Device will eventually connect to a forthcoming radio dashboard
- The future dashboard will allow users to control playlists
- Future capabilities to consider:
  - Remote monitoring of device health
  - Usage statistics reporting to central server
  - Enhanced authentication for remote API access
- Software should be compatible with additional Raspberry Pi versions (3b+, 4b)
