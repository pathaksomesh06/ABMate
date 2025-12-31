# ABMate
<img width="128" height="128" alt="AppIcon" src="https://github.com/user-attachments/assets/799f6794-1565-4092-acca-b08d8658c1d4" />

  
</p>

<p align="center">
  <strong>A native macOS client for Apple Business Manager API</strong>
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#requirements">Requirements</a> •
  <a href="#installation">Installation</a> •
  <a href="#setup">Setup</a> •
  <a href="#usage">Usage</a> •
  <a href="#license">License</a>
</p>

---

## Overview

**ABMate** is a native macOS application built with SwiftUI that provides a modern, user-friendly interface for interacting with the Apple Business Manager (ABM) and Apple School Manager (ASM) APIs. It streamlines device management workflows by replacing complex API calls with an intuitive GUI.

## Features

- 🖥️ **Device Management** - View and manage all enrolled devices
- 📊 **Dashboard** - Quick overview of devices, MDM servers, and status
- 🔄 **Device Assignment** - Bulk assign/unassign devices to MDM servers
- 📤 **Export to CSV** - Export device lists for reporting
- 🔐 **Secure Authentication** - JWT-based authentication with ABM API
- 📱 **Device Breakdown** - View devices by type (Mac, iPhone, iPad, Apple TV)
- ✅ **AppleCare Coverage** - Check warranty and coverage status
- 📋 **Activity Tracking** - Monitor batch operation progress

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15.0 or later (for building from source)
- Apple Business Manager or Apple School Manager account
- ABM API credentials (Client ID, Key ID, Private Key)

## Installation

### Option 1: Download Release
Download the latest release from the [Releases](https://github.com/pathaksomesh06/ABMate/releases) page.

### Option 2: Build from Source
1. Clone the repository:
   ```bash
   git clone https://github.com/pathaksomesh06/ABMate.git
   cd ABMate
   ```

2. Open in Xcode:
   ```bash
   open ABMate.xcodeproj
   ```

3. Build and run (⌘+R)

## Setup

### Getting ABM API Credentials

1. Sign in to [Apple Business Manager](https://business.apple.com)
2. Navigate to **Settings** → **API**
3. Generate a new API key:
   - Note the **Client ID** (starts with `BUSINESSAPI.`)
   - Note the **Key ID**
   - Download the **Private Key** (.p8 file)

### Configuring ABMate

1. Launch ABMate
2. Click **Connection** in the sidebar (or the **Configure** button on the dashboard)
3. Enter your credentials:
   - **Client ID**: Your ABM client ID
   - **Key ID**: Your API key ID
   - **Private Key**: Import your .p8 file
4. Click **Generate JWT Token**
5. Click **Connect to ABM**

## Usage

### Dashboard
The dashboard provides a quick overview of:
- Total devices enrolled
- Number of MDM servers
- Device breakdown by type
- Quick actions for common tasks

### Devices
- View all enrolled devices with search and filter capabilities
- Double-click a device to view details
- Check AppleCare coverage status
- Export device lists to CSV

### Assign Devices
- Bulk assign devices to MDM servers
- Bulk unassign devices from MDM servers
- Track assignment progress

### Activity Status
- Monitor batch operation progress
- Check status of recent assignments

## API Endpoints Used

ABMate interacts with the following Apple Business Manager API endpoints:

| Endpoint | Description |
|----------|-------------|
| `/v1/orgDevices` | List organization devices |
| `/v1/mdmServers` | List MDM servers |
| `/v1/orgDeviceActivities` | Check activity status |
| `/v1/mdmServers/{id}/devices` | Assign devices to MDM |
| `/v1/devices/{id}/appleCare` | Get AppleCare coverage |

## Security

- Credentials are stored securely in the macOS Keychain
- JWT tokens are generated locally using your private key
- No credentials are transmitted to third parties
- All API communication uses HTTPS

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

**Somesh Pathak**
- GitHub: [@pathaksomesh06](https://github.com/pathaksomesh06)
- Blog: [Intune in Real Life](https://intuneinreallife.com)

## Acknowledgments

- Apple Business Manager API Documentation
- SwiftUI and Swift community

---

<p align="center">
  Made with ❤️ for the Apple Admin community
</p>
