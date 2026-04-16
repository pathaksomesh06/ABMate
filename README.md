<img width="1012" height="814" alt="Screenshot 2026-04-16 at 14 31 30" src="https://github.com/user-attachments/assets/9fb62b6f-4245-4c73-bfa6-1bb2dcd2857d" />
# ABMate

<p align="center">
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

## ✨ New Features

### 🎨 Modern SwiftUI Interface
- **Completely redesigned UI** with material-style cards, gradient backgrounds, and smooth staggered animations
- **NavigationSplitView layout** with a persistent sidebar for quick access to Dashboard, Devices, MDM Servers, Assign, and Activity views
- **Live connection badge** showing real-time ABM/ASM connection status
- **New app icon** reflecting the ABMate brand

### 📊 Dashboard
- At-a-glance overview of total devices, MDM servers, and connection status
- Device breakdown by type (Mac, iPhone, iPad, Apple TV)
- Quick-action buttons for common workflows

### 🏫 Dual-Platform Support
- Full support for both **Apple Business** and **Apple School Manager**
- Seamlessly switch between platforms with platform-specific API endpoints, OAuth scopes, and branding
- Credentials and platform selection persist across sessions

### ✅ AppleCare Coverage Lookup
- Check warranty and coverage status for any enrolled device
- View coverage type, end date, repair coverage, and technical support status

### 🔄 Device Assignment & Management
- Bulk assign or unassign devices to MDM servers
- Real-time progress tracking for batch operations
- Activity ID tracking with status polling (status, sub-status, timestamps)

### 📋 Activity Tracking
- Dedicated Activity view to monitor batch operation progress
- Check status of any activity by ID

### 📤 CSV Export
- Export device lists to CSV for reporting and auditing

### 🆕 New Apple Business Features — Complete API Coverage
Apple Business Manager's latest expansion brings powerful new capabilities. ABMate v2.0 is the first native macOS app with full support:

- **Users & User Groups** — Manage Managed Apple IDs and organizational structures at scale
- **Apps & Books** — Browse your entire VPP catalog with full metadata (supports Content Token for complete visibility)
- **Packages** — View and manage custom macOS packages
- **Blueprints** — Inspect automated enrollment configurations for zero-touch deployment (read-only)
- **Configurations** — Review device configuration profiles (read-only)
- **Audit Events** — Complete admin activity tracking with time-range filtering for compliance
- **MDM Enrolled Devices** — Detailed enrollment analytics and device information

<img width="1012" height="814" alt="Screenshot 2026-04-16 at 14 31 30" src="https://github.com/user-attachments/assets/c44fb11a-cc3f-43bd-9ecb-26dd801a19c6" />
<img width="1012" height="814" alt="Screenshot 2026-04-16 at 14 32 16" src="https://github.com/user-attachments/assets/5260a171-add4-4699-9461-a08e8c53b7c7" />
<img width="1012" height="814" alt="Screenshot 2026-04-16 at 14 32 19" src="https://github.com/user-attachments/assets/71078c6f-1894-4466-a348-ef774698b98e" />
<img width="1012" height="814" alt="Screenshot 2026-04-16 at 14 32 13" src="https://github.com/user-attachments/assets/d39d4b70-fb4d-45e5-98d4-0c146cc8f836" />

## Requirements

- macOS 15.5 or later
- Xcode 15.0 or later (for building from source)
- Apple Business Manager or Apple School Manager account
- ABM API credentials (Client ID, Key ID, Private Key)
- Jamf Pro API Client credentials (for inventory sync features)

## Installation

### Option 1: Download Release
Download the latest release from the [Releases](https://github.com/pathaksomesh06/ABMate/releases/tag/v2.0) page.

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

### Connecting Jamf Pro (for Inventory Sync)

1. Open **Connection Settings** and switch to the **MDM Server** tab
2. Enter your Jamf Pro URL, Client ID, and Client Secret
3. Click **Connect** — ABMate authenticates via OAuth 2.0
4. Save the profile for quick reconnection

Your Jamf Pro API Client needs the following privileges: **Read Computers**, **Update Computers**, **Read Mobile Devices**, **Update Mobile Devices**, **Read Users**, **Update Users**.

## Usage

### Dashboard
The dashboard provides an at-a-glance overview centered on inventory comparison. When an MDM server is connected, comparison runs automatically. Key elements include a device breakdown by type (Mac, iPhone, iPad, Apple TV), a clickable MDM server count that navigates to the MDM Servers tab, and Export/Activity buttons in the header for quick access.

### Devices
View all enrolled devices with search, sort, and filter capabilities. Search across serial numbers, models, product types, and order numbers. Each device shows its enrollment status (Assigned/Unassigned) and inventory sync status (Up to Date, Needs Sync, or Not in MDM) when a comparison has been run. Double-click any device to view full details, look up AppleCare coverage, or check the assigned MDM server. Export filtered results to CSV.

### Assign Devices
Bulk assign or unassign devices to MDM servers. Filter by OS, enrollment status, MDM availability, and sync status. Action controls (Assign/Unassign toggle and MDM server picker) are separated from filters for clarity. Select devices in the table and execute assignments with progress tracking.

### Inventory Sync
Compare purchasing data between ASM/ABM and Jamf Pro, then push updates in bulk. Two modes are available: single-device lookup for quick checks with editable fields, and bulk comparison with selective sync. Bulk sync supports test modes (10 computers or 10 mobile devices), full sync, cancel mid-operation, and retry of failed devices. Supports both computers (Jamf v1 API) and mobile devices (Jamf Classic API). Generates exportable sync reports with full logs.

### Activity History
A persistent, filterable timeline of all actions taken in ABMate — connections, syncs, assignments, and exports. Filter by category using chips. History persists across app launches with a sanitized audit trail (no device serials, server URLs, counts, or filenames written to disk). Look up ABM activity IDs directly from the Activity view header.

### MDM Servers
View registered MDM servers from your ASM/ABM account. Select a server to query its assigned devices.

### Connection Profiles
Save multiple ABM/ASM and Jamf Pro connection profiles for quick switching between environments. Sensitive credentials (private keys, client secrets) are stored in the macOS Keychain; only metadata is persisted in UserDefaults.

## API Endpoints Used

### Apple Business Manager / Apple School Manager

| Endpoint | Description |
|----------|-------------|
| `/v1/orgDevices` | List organization devices (paginated) |
| `/v1/mdmServers` | List MDM servers |
| `/v1/orgDeviceActivities` | Check activity status |
| `/v1/mdmServers/{id}/devices` | Assign/unassign devices to MDM |
| `/v1/devices/{id}/appleCare` | Get AppleCare coverage |
| `/v1/orgDevices/{id}/relationships/assignedServer` | Get assigned MDM server for a device |

### Jamf Pro (Inventory Sync)

| Endpoint | Description |
|----------|-------------|
| `/api/oauth/token` | OAuth 2.0 client credentials authentication |
| `/api/v1/computers-inventory` | Fetch computer inventory with purchasing data |
| `/api/v1/computers-inventory-detail/{id}` | Update computer purchasing fields |
| `/api/v2/mobile-devices` | Fetch mobile device list |
| `/api/v2/mobile-devices/{id}/detail` | Fetch mobile device detail |
| `/JSSResource/mobiledevices/id/{id}/subset/Purchasing` | Fetch mobile device purchasing (Classic API) |
| `/JSSResource/mobiledevices/id/{id}` | Update mobile device purchasing (Classic API, XML) |

## Security

- ABM/ASM private keys are stored securely in the macOS Keychain
- Jamf Pro client secrets are stored in the macOS Keychain
- JWT tokens are generated locally using your private key
- Activity history is persisted with sanitized details — no device serials, server URLs, counts, or filenames written to disk
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
- Blog: [Intune in Real Life](https://www.intuneirl.com/)

## Acknowledgments

- Apple Business Manager API Documentation
- SwiftUI and Swift community

---

<p align="center">
  Made with ❤️ for the Apple Admin community
</p>
