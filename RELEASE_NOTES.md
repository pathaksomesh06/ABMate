# ABMate v2.0 Release Notes

## 🚀 Major Release — Complete Redesign & Full Apple Business API Support

ABMate v2.0 is a ground-up rewrite of the former ABM-API-Client, delivering a modern native macOS experience for managing Apple Business and Apple School Manager.

**Apple recently rebranded and massively expanded Apple Business Manager** with new capabilities like Blueprints, built-in device management, and comprehensive APIs. ABMate v2.0 provides **complete API coverage** for all these new features.

---

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

---

## 🔧 Under the Hood

### Resilient API Layer
- **Automatic token refresh** — tokens are transparently refreshed during long paginated fetches (55K+ device support)
- **Exponential backoff with jitter** — smart retry logic for transient errors (429, 502, 503, 504)
- **Retry-After header support** — respects server-specified cooldown periods
- **Partial fetch results** — gracefully returns loaded devices if pagination fails mid-way, instead of losing all progress
- **Session rebuild on network errors** — URLSession is automatically rebuilt after connection-level failures
- **Retryable error detection** — handles NSURLError codes (-1001, -1004, -1005, -1009, -531) with automatic retries

### Connection & Performance
- Optimized URLSession with HTTP/2-safe configuration
- Connection pooling (6 connections per host)
- 1-hour resource timeout for large ABM instances
- Proper cookie handling and cache policy

---

## 📦 Migration Notes

- **Renamed from ABM-API-Client to ABMate** — the Xcode project, bundle, and all source files have been restructured
- **Minimum macOS version raised to 14.0 (Sonoma)** — required for modern SwiftUI APIs (NavigationSplitView, Material effects)
- **Minimum Xcode version raised to 15.0**

---

## Requirements
- macOS 14.0 (Sonoma) or later
- Xcode 15.0 or later (for building from source)
- Apple Business or Apple School Manager account with API credentials

## Known Issues
None at this time.

## Installation
Download the latest release from the [Releases](https://github.com/pathaksomesh06/ABMate/releases) page, or build from source:
```bash
git clone https://github.com/pathaksomesh06/ABMate.git
open ABMate/ABMate.xcodeproj
```

---

## 🎯 Who is this for?

- **IT Administrators** managing Apple devices at enterprise scale
- **Managed Service Providers (MSPs)** supporting multiple Apple Business organizations
- **Developers** building integrations with Apple Business APIs
- **Organizations** requiring compliance reporting and audit trails

---

**Release Date**: April 15, 2026
**Build Version**: 2.0
**Status**: Stable

**Note**: This release coincides with Apple's expansion of Apple Business Manager capabilities. ABMate provides day-one support for all new APIs.
