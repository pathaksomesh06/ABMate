//
//  Models.swift
//  ABMate
//
//  © Created by Somesh Pathak on 23/06/2025.
//

import Foundation

// API Credentials
struct APICredentials: Codable {
    let clientId: String
    let keyId: String
    let privateKey: String
}

// Connection Profile for saving/switching between ABM connections
// Note: privateKey is stored in Keychain, not in UserDefaults with the rest of the profile.
struct ConnectionProfile: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var clientId: String
    var keyId: String
    var privateKey: String

    // Only encode metadata to UserDefaults — privateKey goes to Keychain
    enum CodingKeys: String, CodingKey {
        case id, name, clientId, keyId
    }

    init(id: UUID = UUID(), name: String, clientId: String, keyId: String, privateKey: String) {
        self.id = id
        self.name = name
        self.clientId = clientId
        self.keyId = keyId
        self.privateKey = privateKey
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        clientId = try container.decode(String.self, forKey: .clientId)
        keyId = try container.decode(String.self, forKey: .keyId)
        // Private key will be loaded from Keychain after decoding
        privateKey = ""
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(clientId, forKey: .clientId)
        try container.encode(keyId, forKey: .keyId)
        // privateKey is intentionally NOT encoded — it's stored in Keychain
    }
}

// Token Response
struct TokenResponse: Codable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
    }
}

// Auth Error Response
struct AuthErrorResponse: Codable {
    let error: String
    let errorDescription: String?
    
    enum CodingKeys: String, CodingKey {
        case error
        case errorDescription = "error_description"
    }
}

// Device Model
struct OrgDevice: Codable, Identifiable, Hashable {
    let id: String
    let type: String
    let attributes: DeviceAttributes
    
    struct DeviceAttributes: Codable, Hashable {
        let serialNumber: String
        let deviceModel: String?
        let productFamily: String?
        let productType: String?
        let deviceCapacity: String?
        let color: String?
        let status: String?
        let orderNumber: String?
        let addedToOrgDateTime: String?
        let updatedDateTime: String?
    }
    
    // Convenience accessors
    var serialNumber: String { attributes.serialNumber }
    var name: String? { nil } // ABM API doesn't provide device name
    var model: String? { attributes.deviceModel }
    var os: String? { attributes.productFamily }
    var osVersion: String? { nil } // Not provided by ABM API
    var enrollmentState: String? { attributes.status }
    var productType: String? { attributes.productType }
    var addedDate: String? { attributes.addedToOrgDateTime }
    var updatedDate: String? { attributes.updatedDateTime }
    var capacity: String? { attributes.deviceCapacity }
    var color: String? { attributes.color }
    var orderNumber: String? { attributes.orderNumber }

    // Sortable non-optional accessors (for Table column sorting)
    var sortableModel: String { model ?? "" }
    var sortableOS: String { os ?? "" }
    var sortableStatus: String { enrollmentState ?? "" }
    var sortableAddedDate: String { attributes.addedToOrgDateTime ?? "" }
    var sortableUpdatedDate: String { attributes.updatedDateTime ?? "" }
    var sortableProductType: String { productType ?? "" }

    // Cached formatters — creating these is expensive, so reuse them
    private static let isoFormatterFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
    private static let displayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    /// Format an ISO 8601 date string to a short readable date
    static func formatDate(_ isoString: String?) -> String {
        guard let isoString = isoString, !isoString.isEmpty else { return "—" }
        if let date = isoFormatterFractional.date(from: isoString) {
            return displayFormatter.string(from: date)
        }
        if let date = isoFormatter.date(from: isoString) {
            return displayFormatter.string(from: date)
        }
        // Last resort: just show the first 10 chars (date portion)
        return String(isoString.prefix(10))
    }
}

// Device Response
struct DevicesResponse: Codable {
    let data: [OrgDevice]
    let links: Links?
    
    struct Links: Codable {
        let next: String?
        let prev: String?
    }
}

// MDM Server
struct MDMServer: Codable, Identifiable, Hashable {
    let id: String
    let type: String
    let attributes: MDMServerAttributes
    
    struct MDMServerAttributes: Codable, Hashable {
        let serverName: String
        let serverType: String
        let createdDateTime: String
        let updatedDateTime: String
    }
}

// MDM Servers Response
struct MDMServersResponse: Codable {
    let data: [MDMServer]
    let links: DevicesResponse.Links?
}

// Device Activity
struct DeviceActivity: Codable {
    let data: ActivityData
    
    struct ActivityData: Codable {
        let type: String
        let attributes: ActivityAttributes
        let relationships: ActivityRelationships
    }
    
    struct ActivityAttributes: Codable {
        let activityType: String
    }
    
    struct ActivityRelationships: Codable {
        let mdmServer: MDMServerRelation
        let devices: DevicesRelation
    }
    
    struct MDMServerRelation: Codable {
        let data: RelationData
    }
    
    struct DevicesRelation: Codable {
        let data: [RelationData]
    }
    
    struct RelationData: Codable {
        let type: String
        let id: String
    }
}

// Activity Status Response
struct ActivityStatusResponse: Codable {
    let data: ActivityStatus
    
    struct ActivityStatus: Codable {
        let id: String
        let type: String
        let attributes: StatusAttributes
    }
    
    struct StatusAttributes: Codable {
        let status: String
        let subStatus: String
        let createdDateTime: String
    }
}


// AppleCare Coverage Response — API returns data as an array
struct AppleCareCoverageResponse: Codable {
    let data: [AppleCareCoverage]
}

struct AppleCareCoverage: Codable, Hashable, Identifiable {
    let id: String
    let type: String
    let attributes: AppleCareAttributes

    struct AppleCareAttributes: Codable, Hashable {
        // Fields matching the actual Apple Business/School Manager API response
        let status: String?
        let description: String?
        let startDateTime: String?
        let endDateTime: String?
        let contractCancelDateTime: String?
        let agreementNumber: String?
        let isRenewable: Bool?
        let isCanceled: Bool?
        let paymentType: String?
    }
}

// MARK: - Jamf Pro Models

/// Jamf Pro connection profile — clientSecret stored in Keychain, rest in UserDefaults
struct JamfConnectionProfile: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var jamfURL: String
    var clientId: String
    var clientSecret: String

    enum CodingKeys: String, CodingKey {
        case id, name, jamfURL, clientId
    }

    init(id: UUID = UUID(), name: String, jamfURL: String, clientId: String, clientSecret: String) {
        self.id = id
        self.name = name
        self.jamfURL = jamfURL
        self.clientId = clientId
        self.clientSecret = clientSecret
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        jamfURL = try container.decode(String.self, forKey: .jamfURL)
        clientId = try container.decode(String.self, forKey: .clientId)
        clientSecret = "" // loaded from Keychain
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(jamfURL, forKey: .jamfURL)
        try container.encode(clientId, forKey: .clientId)
    }
}

/// Jamf Pro OAuth token response
struct JamfTokenResponse: Codable {
    let accessToken: String
    let expiresIn: Int
    let tokenType: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
    }
}

/// Jamf Pro computer inventory search response
struct JamfComputerSearchResponse: Codable {
    let totalCount: Int
    let results: [JamfComputer]
}

/// Jamf Pro computer from inventory endpoint
struct JamfComputer: Codable, Identifiable {
    let id: String
    let general: JamfComputerGeneral?
    let hardware: JamfComputerHardware?
    let purchasing: JamfPurchasing?
}

struct JamfComputerGeneral: Codable {
    let name: String?
    let managementId: String?
}

struct JamfComputerHardware: Codable {
    let serialNumber: String?
    let model: String?
    let modelIdentifier: String?
}

/// Jamf Pro purchasing info — used for both reading and writing
struct JamfPurchasing: Codable {
    var purchased: Bool?
    var leased: Bool?
    var poNumber: String?
    var poDate: String?
    var vendor: String?
    var warrantyDate: String?
    var appleCareId: String?
    var leaseDate: String?
    var purchasePrice: String?
    var lifeExpectancy: Int?
    var purchasingAccount: String?
    var purchasingContact: String?
}

/// Wrapper for PATCH /api/v1/computers-inventory-detail/{id}
struct JamfComputerDetailUpdate: Codable {
    let purchasing: JamfPurchasing
}

/// Jamf Pro mobile device search response
struct JamfMobileDeviceSearchResponse: Codable {
    let totalCount: Int
    let results: [JamfMobileDevice]
}

struct JamfMobileDevice: Codable, Identifiable {
    let id: String
    let name: String?
    let serialNumber: String?
    let model: String?
}

/// Jamf mobile device detail (for reading purchasing info)
struct JamfMobileDeviceDetail: Codable {
    let id: String
    let purchasing: JamfPurchasing?
}

/// Wrapper for PATCH /api/v2/mobile-devices/{id}
struct JamfMobileDeviceUpdate: Codable {
    let purchasing: JamfPurchasing
}

/// Represents a device found in Jamf Pro (computer or mobile)
enum JamfDeviceType: String {
    case computer = "Computer"
    case mobileDevice = "Mobile Device"
}

struct JamfDeviceMatch {
    let id: String
    let name: String
    let serial: String
    let model: String
    let deviceType: JamfDeviceType
    let currentPurchasing: JamfPurchasing?
}

/// Represents what we want to sync from ASM to Jamf
struct SyncPayload {
    let poNumber: String
    let warrantyDate: String
    let appleCareId: String
    let purchasePrice: String
    let vendor: String
    let purchasingAccount: String
    let purchasingContact: String
    let leaseDate: String
    let lifeExpectancy: Int
    let purchased: Bool
    let leased: Bool
    let poDate: String

    /// Convert to Jamf purchasing object
    func toJamfPurchasing() -> JamfPurchasing {
        JamfPurchasing(
            purchased: purchased,
            leased: leased,
            poNumber: poNumber.isEmpty ? nil : poNumber,
            poDate: poDate.isEmpty ? nil : poDate,
            vendor: vendor.isEmpty ? nil : vendor,
            warrantyDate: warrantyDate.isEmpty ? nil : warrantyDate,
            appleCareId: appleCareId.isEmpty ? nil : appleCareId,
            leaseDate: leaseDate.isEmpty ? nil : leaseDate,
            purchasePrice: purchasePrice.isEmpty ? nil : purchasePrice,
            lifeExpectancy: lifeExpectancy,
            purchasingAccount: purchasingAccount.isEmpty ? nil : purchasingAccount,
            purchasingContact: purchasingContact.isEmpty ? nil : purchasingContact
        )
    }
}
