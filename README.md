# ABM/ASM API Client for macOS

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![macOS](https://img.shields.io/badge/macOS-26+-blue?logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.10+-orange?logo=swift&logoColor=white)](https://developer.apple.com/swift/)
[![Xcode](https://img.shields.io/badge/Xcode-15.0+-blue?logo=xcode&logoColor=white)](https://developer.apple.com/xcode/)

A native macOS client built with Swift to provide a graphical user interface (GUI) for the new Apple Business Manager (ABM) and Apple School Manager (ASM) REST APIs. This project aims to revolutionize large-scale Apple device management by moving beyond command-line interfaces and cumbersome web portals, enabling effortless and automated workflows.

## Introduction

Managing thousands of Apple devices in enterprise and education environments has historically been a manual, time-consuming process. IT administrators spend countless hours clicking through web interfaces to assign devices to MDM servers, check enrollment status, and generate reports. With Apple's introduction of REST APIs for Apple Business Manager (ABM) and Apple School Manager (ASM) at WWDC 2025, this paradigm shifts dramatically.

This project presents a complete walkthrough of building a production-ready native macOS client that leverages these APIs to transform device management workflows. We'll explore the technical architecture, implementation challenges, security considerations, and real-world performance improvements achieved through API automation.

## The Problem: Manual Device Management at Scale

Before we unveil the solution, let's confront the significant hurdles IT teams navigate daily when managing vast Apple device fleets:

**1. Time Sinks, Not Time Savers:**
    * **Tedious Assignments:** Allocating 100 devices to an MDM server can consume 15-20 minutes and require roughly 300 clicks.
    * **Clunky Reporting:** Manual CSV exports offer limited filtering, making comprehensive reporting a slog.
    * **Status Quo Struggles:** Checking assignment status means navigating countless pages, one at a time.

**2. The Inevitable Human Factor:**
    * **Misclicks & Mistakes:** Bulk selections are ripe for errors, leading to incorrect assignments.
    * **Inconsistent Data:** Manual processes breed variations in device naming and MDM server allocation.

**3. Automation's Missing Link:**
    * **No Scheduled Tasks:** Routine operations demand constant manual intervention.
    * **Rules? What Rules?:** Lack of rule-based assignments prevents proactive management.
    * **Isolated Systems:** No seamless integration with essential ticketing or inventory systems.

**4. Blurry Visibility:**
    * **Lagging Data:** Real-time status updates are a pipe dream, leaving IT in the dark.
    * **Basic Insights:** Reporting rarely offers the granular detail needed for informed decisions.
    * **Absent History:** Tracking past activities is challenging, hindering troubleshooting and auditing.

## Apple's Game-Changing API Release: Powering Our macOS Client

At the heart of this revolution in device management lies Apple's new RESTful API, offering robust programmatic access to core Apple Business Manager (ABM) and Apple School Manager (ASM) functionalities. This foundational technology is what makes our native macOS client so powerful.

**API Essentials:**

* **Base URL:** `https://api-business.apple.com/v1/`
* **Authentication:** Secure OAuth 2.0 with JWT Client Assertions.
* **Rate Limits:** A generous 100 requests per second.
* **Pagination:** Efficient link-based pagination, defaulting to 100 items per page.

**Key Endpoints for Comprehensive Control:**

The API exposes critical endpoints, enabling the granular device management capabilities within our client:

* **Device Information:**
    * `GET /v1/orgDevices` — List all organizational devices.
    * `GET /v1/orgDevices/{id}` — Get detailed information for a specific device.
    * `GET /v1/orgDevices/{id}/relationships/assignedServer` — Determine a device's assigned MDM server.
* **MDM Server Operations:**
    * `GET /v1/mdmServers` — Retrieve a list of all registered MDM servers.
    * `GET /v1/mdmServers/{id}/relationships/devices` — View devices associated with a particular MDM server.
* **Powerful Batch Operations:**
    * `POST /v1/orgDeviceActivities` — Execute bulk assignments or unassignments of devices.
    * `GET /v1/orgDeviceActivities/{id}` — Monitor the status of ongoing batch operations.

## Authentication Flow: JWT-Based Security

Apple's API authentication moves beyond simple API keys, leveraging a more secure and robust JWT (JSON Web Token) based mechanism. Here's a breakdown of the multi-step process:

**1. Initial Setup in ABM:**

* **Create an API Key:** Begin by generating an API key directly within your Apple Business Manager account.
* **Generate Private Key:** During this process, you'll generate a private key (using the P-256 elliptic curve), which is crucial for signing your JWTs.
* **Note Credentials:** Securely record your unique **Client ID** and **Key ID** — these identify your application.
* **Secure Storage:** Crucially, the generated private key must be stored in a highly secure manner.

**2. Generating the JWT Client Assertion:**

This is the signed token your application creates to assert its identity. It consists of a header and a payload:

```json
// JWT Header: Specifies the algorithm and key ID
{
  "alg": "ES256", // Elliptic Curve Digital Signature Algorithm using P-256 and SHA-256
  "kid": "your-key-id", // Your unique Key ID from ABM
  "typ": "JWT"        // Token type
}

// JWT Payload: Contains claims about the assertion
{
  "sub": "BUSINESSAPI.client-id",                         // The subject (your Client ID, prefixed)
  "aud": "[https://account.apple.com/auth/oauth2/v2/token](https://account.apple.com/auth/oauth2/v2/token)", // The audience (Apple's token endpoint)
  "iat": 1719263110,                                       // Issued At timestamp (Unix epoch time)
  "exp": 1734815110,                                       // Expiration timestamp (Unix epoch time)
  "jti": "unique-token-id",                                // Unique JWT ID for replay prevention
  "iss": "BUSINESSAPI.client-id"                          // The issuer (your Client ID, prefixed)
}
