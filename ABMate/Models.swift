//
//  Models.swift
//  ABMate
//
//  © Created by Somesh Pathak on 23/06/2025.
//

import Foundation

// MARK: - Platform

enum ApplePlatform: String, CaseIterable, Identifiable, Codable {
    case business
    case school

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .business:
            return "Apple Business Manager"
        case .school:
            return "Apple School Manager"
        }
    }

    var shortName: String {
        switch self {
        case .business:
            return "ABM"
        case .school:
            return "ASM"
        }
    }

    var apiBaseURL: String {
        switch self {
        case .business:
            return "https://api-business.apple.com"
        case .school:
            return "https://api-school.apple.com"
        }
    }

    var oauthScope: String {
        switch self {
        case .business:
            return "business.api"
        case .school:
            return "school.api"
        }
    }

    /// Features only available in Apple Business Manager (not ASM)
    var supportsUsers: Bool { self == .business }
    var supportsUserGroups: Bool { self == .business }
    var supportsApps: Bool { self == .business }
    var supportsPackages: Bool { self == .business }
    var supportsBlueprints: Bool { self == .business }
    var supportsConfigurations: Bool { self == .business }
    var supportsAuditEvents: Bool { self == .business }
    var supportsMdmEnrolledDevices: Bool { self == .business }
}

// API Credentials
struct APICredentials: Codable {
    let clientId: String
    let keyId: String
    let privateKey: String
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
    var name: String? { nil } // Apple Business/School Manager API doesn't provide device name
    var model: String? { attributes.deviceModel }
    var os: String? { attributes.productFamily }
    var osVersion: String? { nil } // Not provided by ABM/ASM API
    var enrollmentState: String? { attributes.status }
    var productType: String? { attributes.productType }
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


// AppleCare Coverage Response
struct AppleCareCoverageResponse: Codable {
    let data: AppleCareCoverage
}

struct AppleCareCoverage: Codable, Hashable {
    let id: String
    let type: String
    let attributes: AppleCareAttributes
    
    struct AppleCareAttributes: Codable, Hashable {
        // All fields are optional since API might not return all of them
        let serialNumber: String?
        let coverageStatus: String?
        let coverageEndDate: String?
        let purchaseDate: String?
        let registrationDate: String?
        let warrantyStatus: String?
        let repairCoverage: String?
        let technicalSupportCoverage: String?
        let appleCarePlanType: String?
        let deviceId: String?
        let hardwareType: String?
        let estimatedPurchaseDate: String?
        let coverageType: String?
        
        // Handle different key naming conventions from API
        enum CodingKeys: String, CodingKey {
            case serialNumber
            case coverageStatus
            case coverageEndDate
            case purchaseDate
            case registrationDate
            case warrantyStatus
            case repairCoverage
            case technicalSupportCoverage
            case appleCarePlanType
            case deviceId
            case hardwareType
            case estimatedPurchaseDate
            case coverageType
        }
    }
}

// MARK: - Users (ABM only)

struct ABMUser: Codable, Identifiable, Hashable {
    let id: String
    let type: String
    let attributes: UserAttributes
    
    struct UserAttributes: Codable, Hashable {
        let firstName: String?
        let lastName: String?
        let email: String?
        let managedAppleId: String?
        let status: String?
        let roles: [UserRoleOuMapping]?
        let phoneNumbers: [UserPhoneNumber]?
    }
    
    var displayName: String {
        let first = attributes.firstName ?? ""
        let last = attributes.lastName ?? ""
        let full = "\(first) \(last)".trimmingCharacters(in: .whitespaces)
        return full.isEmpty ? (attributes.email ?? id) : full
    }
}

struct UserRoleOuMapping: Codable, Hashable {
    let role: String?
    let organizationalUnit: String?
}

struct UserPhoneNumber: Codable, Hashable {
    let number: String?
    let type: String?
}

struct ABMUsersResponse: Codable {
    let data: [ABMUser]
    let links: PagedLinks?
}

struct ABMUserResponse: Codable {
    let data: ABMUser
}

// MARK: - User Groups (ABM only)

struct ABMUserGroup: Codable, Identifiable, Hashable {
    let id: String
    let type: String
    let attributes: UserGroupAttributes
    
    struct UserGroupAttributes: Codable, Hashable {
        let name: String?
        let status: String?
        let groupType: String?
        let createdDateTime: String?
        let updatedDateTime: String?
    }
}

struct ABMUserGroupsResponse: Codable {
    let data: [ABMUserGroup]
    let links: PagedLinks?
}

struct ABMUserGroupResponse: Codable {
    let data: ABMUserGroup
}

// MARK: - Apps (ABM only)

struct ABMApp: Codable, Identifiable, Hashable {
    let id: String
    let type: String
    let attributes: AppAttributes
    
    struct AppAttributes: Codable, Hashable {
        let name: String?
        let bundleId: String?
        let websiteUrl: String?
        let version: String?
        let supportedOS: [String]?
        let isCustomApp: Bool?
        let appStoreUrl: String?
        // Extra fields populated from VPP / iTunes lookup
        let artistName: String?
        let deviceFamilies: [String]?
        let priceFormatted: String?
        // VPP license counts
        let assignedCount: Int?
        let availableCount: Int?
        let totalCount: Int?
        
        init(name: String? = nil, bundleId: String? = nil, websiteUrl: String? = nil, version: String? = nil, supportedOS: [String]? = nil, isCustomApp: Bool? = nil, appStoreUrl: String? = nil, artistName: String? = nil, deviceFamilies: [String]? = nil, priceFormatted: String? = nil, assignedCount: Int? = nil, availableCount: Int? = nil, totalCount: Int? = nil) {
            self.name = name
            self.bundleId = bundleId
            self.websiteUrl = websiteUrl
            self.version = version
            self.supportedOS = supportedOS
            self.isCustomApp = isCustomApp
            self.appStoreUrl = appStoreUrl
            self.artistName = artistName
            self.deviceFamilies = deviceFamilies
            self.priceFormatted = priceFormatted
            self.assignedCount = assignedCount
            self.availableCount = availableCount
            self.totalCount = totalCount
        }
    }
}

struct ABMAppsResponse: Codable {
    let data: [ABMApp]
    let links: PagedLinks?
}

struct ABMAppResponse: Codable {
    let data: ABMApp
}

// MARK: - Packages (ABM only)

struct ABMPackage: Codable, Identifiable, Hashable {
    let id: String
    let type: String
    let attributes: PackageAttributes
    
    struct PackageAttributes: Codable, Hashable {
        let name: String?
        let bundleId: String?
        let version: String?
        let supportedOS: [String]?
    }
}

struct ABMPackagesResponse: Codable {
    let data: [ABMPackage]
    let links: PagedLinks?
}

struct ABMPackageResponse: Codable {
    let data: ABMPackage
}

// MARK: - Blueprints (ABM only)

struct Blueprint: Codable, Identifiable, Hashable {
    let id: String
    let type: String
    let attributes: BlueprintAttributes
    
    struct BlueprintAttributes: Codable, Hashable {
        let name: String?
        let createdDateTime: String?
        let updatedDateTime: String?
    }
}

struct BlueprintsResponse: Codable {
    let data: [Blueprint]
    let links: PagedLinks?
}

struct BlueprintResponse: Codable {
    let data: Blueprint
}

struct BlueprintCreateRequest: Codable {
    let data: BlueprintCreateData
    
    struct BlueprintCreateData: Codable {
        let type: String
        let attributes: BlueprintCreateAttributes
    }
    
    struct BlueprintCreateAttributes: Codable {
        let name: String
    }
    
    init(name: String) {
        self.data = BlueprintCreateData(
            type: "blueprints",
            attributes: BlueprintCreateAttributes(name: name)
        )
    }
}

struct BlueprintUpdateRequest: Codable {
    let data: BlueprintUpdateData
    
    struct BlueprintUpdateData: Codable {
        let type: String
        let id: String
        let attributes: BlueprintUpdateAttributes
    }
    
    struct BlueprintUpdateAttributes: Codable {
        let name: String
    }
    
    init(id: String, name: String) {
        self.data = BlueprintUpdateData(
            type: "blueprints",
            id: id,
            attributes: BlueprintUpdateAttributes(name: name)
        )
    }
}

// MARK: - Configurations (ABM only)

struct ABMConfiguration: Codable, Identifiable, Hashable {
    let id: String
    let type: String
    let attributes: ConfigurationAttributes
    
    struct ConfigurationAttributes: Codable, Hashable {
        let name: String?
        let configurationType: String?
        let createdDateTime: String?
        let updatedDateTime: String?
    }
}

struct ABMConfigurationsResponse: Codable {
    let data: [ABMConfiguration]
    let links: PagedLinks?
}

struct ABMConfigurationResponse: Codable {
    let data: ABMConfiguration
}

struct ConfigurationCreateRequest: Codable {
    let data: ConfigurationCreateData
    
    struct ConfigurationCreateData: Codable {
        let type: String
        let attributes: ConfigurationCreateAttributes
    }
    
    struct ConfigurationCreateAttributes: Codable {
        let name: String
        let configurationType: String
    }
    
    init(name: String) {
        self.data = ConfigurationCreateData(
            type: "configurations",
            attributes: ConfigurationCreateAttributes(name: name, configurationType: "CUSTOM_SETTING")
        )
    }
}

struct ConfigurationUpdateRequest: Codable {
    let data: ConfigurationUpdateData
    
    struct ConfigurationUpdateData: Codable {
        let type: String
        let id: String
        let attributes: ConfigurationUpdateAttributes
    }
    
    struct ConfigurationUpdateAttributes: Codable {
        let name: String
    }
    
    init(id: String, name: String) {
        self.data = ConfigurationUpdateData(
            type: "configurations",
            id: id,
            attributes: ConfigurationUpdateAttributes(name: name)
        )
    }
}

// MARK: - Audit Events (ABM only)

struct AuditEvent: Codable, Identifiable, Hashable {
    let id: String
    let type: String
    let attributes: AuditEventAttributes
    
    struct AuditEventAttributes: Codable, Hashable {
        let eventDateTime: String?
        let eventType: String?
        let category: String?
        let actorType: String?
        let actorId: String?
        let actorName: String?
        let subjectType: String?
        let subjectId: String?
        let subjectName: String?
        let outcome: String?
        let groupId: String?
        
        // Use a flexible key mapping since the API field name is "type"
        enum CodingKeys: String, CodingKey {
            case eventDateTime
            case eventType = "type"
            case category
            case actorType
            case actorId
            case actorName
            case subjectType
            case subjectId
            case subjectName
            case outcome
            case groupId
        }
    }
}

struct AuditEventsResponse: Codable {
    let data: [AuditEvent]
    let links: PagedLinks?
}

// MARK: - MDM Enrolled Devices (ABM only)

struct MdmEnrolledDevice: Codable, Identifiable, Hashable {
    let id: String
    let type: String
    let attributes: MdmEnrolledDeviceAttributes
    
    struct MdmEnrolledDeviceAttributes: Codable, Hashable {
        let deviceName: String?
        let enrolledUserId: String?
        let productFamily: String?
        let serialNumber: String?
    }
}

struct MdmEnrolledDevicesResponse: Codable {
    let data: [MdmEnrolledDevice]
    let links: PagedLinks?
}

struct MdmEnrolledDeviceDetail: Codable, Identifiable, Hashable {
    let id: String
    let type: String
    let attributes: MdmEnrolledDeviceDetailAttributes
    
    struct MdmEnrolledDeviceDetailAttributes: Codable, Hashable {
        let deviceName: String?
        let enrolledUserId: String?
        let productFamily: String?
        let serialNumber: String?
        let osVersion: String?
        let modelName: String?
        let model: String?
        let color: String?
    }
}

struct MdmEnrolledDeviceDetailResponse: Codable {
    let data: MdmEnrolledDeviceDetail
}

// MARK: - Shared Paging Links

struct PagedLinks: Codable {
    let next: String?
    let prev: String?
    let first: String?
    let last: String?
    
    // Make decoding lenient — not all fields are always present
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        next = try container.decodeIfPresent(String.self, forKey: .next)
        prev = try container.decodeIfPresent(String.self, forKey: .prev)
        first = try container.decodeIfPresent(String.self, forKey: .first)
        last = try container.decodeIfPresent(String.self, forKey: .last)
    }
    
    enum CodingKeys: String, CodingKey {
        case next, prev, first, last
    }
}

// MARK: - Generic Linkage Response

struct LinkageResponse: Codable {
    let data: [LinkageData]
    let links: PagedLinks?
    
    struct LinkageData: Codable {
        let type: String
        let id: String
    }
}

struct LinkageRequest: Codable {
    let data: [LinkageData]
    
    struct LinkageData: Codable {
        let type: String
        let id: String
    }
    
    init(type: String, ids: [String]) {
        self.data = ids.map { LinkageData(type: type, id: $0) }
    }
}

// MARK: - VPP / Apps & Books API Models

struct VPPAssetsResponse: Codable {
    let assets: [VPPAsset]?
    let currentPageIndex: Int?
    let nextPageIndex: Int?
    let size: Int?
    let totalPages: Int?
}

struct VPPAsset: Codable {
    let adamId: String
    let assignedCount: Int?
    let availableCount: Int?
    let deviceAssignable: Bool?
    let pricingParam: String?
    let productType: String?
    let retiredCount: Int?
    let revocable: Bool?
    let totalCount: Int?
    let supportedPlatforms: [String]?
}

// MARK: - iTunes Lookup API Models

struct ITunesLookupResponse: Codable {
    let resultCount: Int
    let results: [ITunesApp]
}

struct ITunesApp: Codable {
    let trackId: Int?
    let trackName: String?
    let bundleId: String?
    let artistName: String?
    let artworkUrl100: String?
    let formattedPrice: String?
    let version: String?
    let primaryGenreName: String?
    let trackViewUrl: String?
    let supportedDevices: [String]?
}
