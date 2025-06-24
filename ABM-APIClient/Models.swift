//
//  Models.swift
//  ABM-APIClient
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

// Device Model
struct OrgDevice: Codable, Identifiable, Hashable {
    let id: String
    let type: String
    let attributes: DeviceAttributes
    
    struct DeviceAttributes: Codable, Hashable {
        let serialNumber: String
        let name: String?
        let model: String?
        let deviceFamily: String?
        let osVersion: String?
        let status: String?
    }
    
    
    var serialNumber: String { attributes.serialNumber }
    var name: String? { attributes.name }
    var model: String? { attributes.model }
    var os: String? { attributes.deviceFamily }
    var osVersion: String? { attributes.osVersion }
    var enrollmentState: String? { attributes.status }
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
