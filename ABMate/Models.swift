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
