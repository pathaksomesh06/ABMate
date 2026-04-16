//
//  APIService.swift
//  ABMate
//
//  © Created by Somesh Pathak on 23/06/2025.
//


import Foundation

class APIService {
    private var accessToken: String?
    private var tokenExpiry: Date?
    private var tokenPlatform: ApplePlatform?
    private var urlSession: URLSession

    // Stored credentials for transparent token refresh during long pagination
    private var lastClientAssertion: String?
    private var lastClientId: String?
    private var lastPlatform: ApplePlatform?

    // Error codes that are safe to retry
    private static let retryableErrorCodes: Set<Int> = [
        -1001, // NSURLErrorTimedOut
        -1004, // NSURLErrorCannotConnectToHost
        -1005, // NSURLErrorNetworkConnectionLost
        -1009, // NSURLErrorNotConnectedToInternet
        -531   // CFNetworkErrors
    ]

    // HTTP status codes that are safe to retry
    private static let retryableHTTPCodes: Set<Int> = [
        429,   // Too Many Requests
        503,   // Service Unavailable
        502,   // Bad Gateway
        504    // Gateway Timeout
    ]

    private func makeRequest(url: URL, method: String = "GET", headers: [String: String]? = nil, body: Data? = nil, maxRetries: Int = 5) async throws -> (data: Data, response: URLResponse) {
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        // Retry logic for connection and transient HTTP errors
        var lastError: Error?
        for attempt in 0..<maxRetries {
            do {
                let (data, response) = try await urlSession.data(for: request)

                // Check for retryable HTTP status codes
                if let httpResponse = response as? HTTPURLResponse,
                   APIService.retryableHTTPCodes.contains(httpResponse.statusCode) {
                    if attempt < maxRetries - 1 {
                        let backoff = backoffDelay(attempt: attempt, response: httpResponse)
                        print("HTTP \(httpResponse.statusCode) on attempt \(attempt + 1), retrying after \(backoff)s...")
                        try await Task.sleep(nanoseconds: UInt64(backoff * 1_000_000_000))
                        continue
                    }
                }

                return (data, response)
            } catch let error as NSError {
                lastError = error
                if APIService.retryableErrorCodes.contains(error.code) {
                    if attempt < maxRetries - 1 {
                        rebuildSession()
                        let backoff = backoffDelay(attempt: attempt)
                        print("Network error \(error.code) on attempt \(attempt + 1), retrying after \(backoff)s...")
                        try await Task.sleep(nanoseconds: UInt64(backoff * 1_000_000_000))
                        continue
                    }
                }
                throw error
            }
        }
        
        throw lastError ?? NSError(domain: "Network", code: -1, userInfo: [NSLocalizedDescriptionKey: "Request failed after \(maxRetries) attempts"])
    }

    /// Exponential backoff with jitter; respects Retry-After header for 429s
    private func backoffDelay(attempt: Int, response: HTTPURLResponse? = nil) -> Double {
        // Respect Retry-After header if present
        if let retryAfter = response?.value(forHTTPHeaderField: "Retry-After"),
           let seconds = Double(retryAfter) {
            return min(seconds, 60) // Cap at 60s
        }
        // Exponential backoff: 1s, 2s, 4s, 8s, 16s (capped at 30s) + jitter
        let base = min(pow(2.0, Double(attempt)), 30.0)
        let jitter = Double.random(in: 0...0.5)
        return base + jitter
    }
    
    init() {
        self.urlSession = APIService.makeURLSession()
    }

    private static func makeURLSession() -> URLSession {
        // Configure URLSession with proper HTTP/2 settings
        let config = URLSessionConfiguration.default
        
        config.waitsForConnectivity = true
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 3600 // 1 hour — needed for large ABM instances (55K+ devices)
        
        // Connection pool settings for handling large numbers of devices
        config.httpMaximumConnectionsPerHost = 6
        
        // Cookie handling
        config.httpShouldSetCookies = true
        config.httpCookieAcceptPolicy = .always
        
        // Proper handling of connection lifecycle
        config.urlCache = URLCache.shared
        config.requestCachePolicy = .useProtocolCachePolicy
        
        // Avoid HTTP/2-prohibited headers like Connection
        config.httpAdditionalHeaders = [
            "User-Agent": "ABMate/1.0"
        ]
        
        return URLSession(configuration: config)
    }

    func resetToken() {
        accessToken = nil
        tokenExpiry = nil
        tokenPlatform = nil
    }

    private func rebuildSession() {
        let oldSession = urlSession
        urlSession = APIService.makeURLSession()
        oldSession.finishTasksAndInvalidate()
    }

    private func apiURL(platform: ApplePlatform, path: String) -> URL {
        return URL(string: "\(platform.apiBaseURL)\(path)")!
    }
    
    // Get access token
    func getAccessToken(clientAssertion: String, clientId: String, platform: ApplePlatform) async throws -> String {
        // Check if we have valid token
        if let token = accessToken, let expiry = tokenExpiry, let currentPlatform = tokenPlatform,
           expiry > Date(), currentPlatform == platform {
            return token
        }
    
        // Create request
        var request = URLRequest(url: URL(string: "https://account.apple.com/auth/oauth2/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // Create body
        let bodyParams = [
            "grant_type": "client_credentials",
            "client_id": clientId,
            "client_assertion_type": "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
            "client_assertion": clientAssertion,
            "scope": platform.oauthScope
        ]
        
        let bodyString = bodyParams
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
        
        request.httpBody = bodyString.data(using: .utf8)
        
        // Make request with retry logic
        let (data, response) = try await makeRequest(
            url: URL(string: "https://account.apple.com/auth/oauth2/token")!,
            method: "POST",
            headers: ["Content-Type": "application/x-www-form-urlencoded"],
            body: bodyString.data(using: .utf8)
        )
        
        // Debug the response from Apple's auth server
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            let errorBody = String(data: data, encoding: .utf8) ?? "No response body"
            print("Apple Auth Error (\(httpResponse.statusCode)): \(errorBody)")
            // Try to decode a potential error response
            if let authError = try? JSONDecoder().decode(AuthErrorResponse.self, from: data) {
                throw NSError(domain: "Auth", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Authentication failed: \(authError.error) - \(authError.errorDescription ?? "")"])
            } else {
                throw NSError(domain: "Auth", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "An unknown authentication error occurred. Response: \(errorBody)"])
            }
        }
        
        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        
        // Store token and expiry
        self.accessToken = tokenResponse.accessToken
        self.tokenExpiry = Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn))
        self.tokenPlatform = platform

        // Store credentials for transparent token refresh during long pagination
        self.lastClientAssertion = clientAssertion
        self.lastClientId = clientId
        self.lastPlatform = platform

        return tokenResponse.accessToken
    }
    
    // Check activity status
    func checkActivityStatus(activityId: String, accessToken: String, platform: ApplePlatform) async throws -> ActivityStatusResponse {
        let url = apiURL(platform: platform, path: "/v1/orgDeviceActivities/\(activityId)")
        let headers = ["Authorization": "Bearer \(accessToken)"]
        
        let (data, _) = try await makeRequest(url: url, headers: headers)
        return try JSONDecoder().decode(ActivityStatusResponse.self, from: data)
    }
    
    // Result type for partial fetch results
    struct FetchResult {
        let devices: [OrgDevice]
        let pagesCompleted: Int
        let isTruncated: Bool
        let error: Error?
    }

    // Fetch devices with progress reporting and token refresh for large ABM instances
    func fetchDevices(accessToken: String, platform: ApplePlatform, progress: (@Sendable (Int) -> Void)? = nil) async throws -> FetchResult {
        var allDevices: [OrgDevice] = []
        var currentToken = accessToken
        var nextURL: String? = apiURL(platform: platform, path: "/v1/orgDevices").absoluteString
        var pageCount = 0
        var consecutiveFailures = 0
        let maxConsecutiveFailures = 3
        
        while let urlString = nextURL {
            guard let url = URL(string: urlString) else { break }
            pageCount += 1

            // Refresh token if nearing expiry (< 5 min remaining)
            if let expiry = tokenExpiry, expiry.timeIntervalSinceNow < 300,
               let assertion = lastClientAssertion, let clientId = lastClientId, let plat = lastPlatform {
                print("Token expiring soon, refreshing before page \(pageCount)...")
                currentToken = try await getAccessToken(clientAssertion: assertion, clientId: clientId, platform: plat)
            }

            let headers = [
                "Authorization": "Bearer \(currentToken)",
                "Accept": "application/json"
            ]
            
            do {
                let (data, response) = try await makeRequest(url: url, headers: headers)
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("Page \(pageCount) - Status: \(httpResponse.statusCode), Devices so far: \(allDevices.count)")
                    if httpResponse.statusCode == 401 {
                        // Token expired mid-pagination — try refreshing once
                        if let assertion = lastClientAssertion, let clientId = lastClientId, let plat = lastPlatform {
                            print("Got 401, refreshing token and retrying page \(pageCount)...")
                            self.accessToken = nil
                            self.tokenExpiry = nil
                            currentToken = try await getAccessToken(clientAssertion: assertion, clientId: clientId, platform: plat)
                            let retryHeaders = [
                                "Authorization": "Bearer \(currentToken)",
                                "Accept": "application/json"
                            ]
                            let (retryData, retryResponse) = try await makeRequest(url: url, headers: retryHeaders)
                            if let retryHttp = retryResponse as? HTTPURLResponse, retryHttp.statusCode != 200 {
                                // 401 after refresh — return partial results
                                let error = NSError(domain: "API", code: retryHttp.statusCode,
                                            userInfo: [NSLocalizedDescriptionKey: "API returned status \(retryHttp.statusCode) after token refresh"])
                                print("Returning \(allDevices.count) partial devices after auth failure")
                                return FetchResult(devices: allDevices, pagesCompleted: pageCount - 1, isTruncated: true, error: error)
                            }
                            let retryDeviceResponse = try JSONDecoder().decode(DevicesResponse.self, from: retryData)
                            allDevices.append(contentsOf: retryDeviceResponse.data)
                            nextURL = retryDeviceResponse.links?.next
                            consecutiveFailures = 0
                            progress?(allDevices.count)
                            continue
                        }
                    }
                    if httpResponse.statusCode != 200 {
                        let errorMsg = String(data: data, encoding: .utf8) ?? "No data"
                        print("Response: \(errorMsg)")
                        let error = NSError(domain: "API", code: httpResponse.statusCode,
                                    userInfo: [NSLocalizedDescriptionKey: "API returned status \(httpResponse.statusCode)"])
                        if !allDevices.isEmpty {
                            print("Returning \(allDevices.count) partial devices after HTTP \(httpResponse.statusCode)")
                            return FetchResult(devices: allDevices, pagesCompleted: pageCount - 1, isTruncated: true, error: error)
                        }
                        throw error
                    }
                }
                
                // Debug: Print raw JSON for first page
                if allDevices.isEmpty {
                    print("Raw Device Response: \(String(data: data, encoding: .utf8) ?? "No data")")
                }
                
                let deviceResponse = try JSONDecoder().decode(DevicesResponse.self, from: data)
                
                allDevices.append(contentsOf: deviceResponse.data)
                nextURL = deviceResponse.links?.next
                consecutiveFailures = 0
                progress?(allDevices.count)
            } catch {
                consecutiveFailures += 1
                print("Page \(pageCount) failed (consecutive: \(consecutiveFailures)): \(error.localizedDescription)")
                
                // If we have partial data and hit too many consecutive failures, return what we have
                if !allDevices.isEmpty && consecutiveFailures >= maxConsecutiveFailures {
                    print("Returning \(allDevices.count) partial devices after \(consecutiveFailures) consecutive failures")
                    return FetchResult(devices: allDevices, pagesCompleted: pageCount - 1, isTruncated: true, error: error)
                }
                
                // If we have no data at all, propagate the error
                if allDevices.isEmpty {
                    throw error
                }

                // Single failure with partial data — retry this page
                pageCount -= 1
                // Small delay before retrying
                try await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }
        
        print("Fetch complete: \(allDevices.count) devices across \(pageCount) pages")
        return FetchResult(devices: allDevices, pagesCompleted: pageCount, isTruncated: false, error: nil)
    }
    
    // Get device by ID
    func getDevice(id: String, accessToken: String, platform: ApplePlatform) async throws -> OrgDevice {
        let url = apiURL(platform: platform, path: "/v1/orgDevices/\(id)")
        let headers = ["Authorization": "Bearer \(accessToken)"]
        
        let (data, _) = try await makeRequest(url: url, headers: headers)
        let response = try JSONDecoder().decode(DeviceDetailResponse.self, from: data)
        return response.data
    }
    
    // Get AppleCare Coverage for a device
    func getAppleCareCoverage(deviceId: String, accessToken: String, platform: ApplePlatform) async throws -> AppleCareCoverage {
        let url = apiURL(platform: platform, path: "/v1/orgDevices/\(deviceId)/appleCareCoverage")
        let headers = [
            "Authorization": "Bearer \(accessToken)",
            "Accept": "application/json"
        ]
        
        let (data, response) = try await makeRequest(url: url, headers: headers)
        
        // Always print raw response for debugging
        let responseString = String(data: data, encoding: .utf8) ?? "No data"
        print("AppleCare Raw Response: \(responseString)")
        
        if let httpResponse = response as? HTTPURLResponse {
            print("AppleCare Status Code: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode != 200 {
                let errorMessage: String
                switch httpResponse.statusCode {
                case 404:
                    errorMessage = "No AppleCare coverage information available for this device."
                default:
                    errorMessage = "AppleCare API returned status \(httpResponse.statusCode)"
                }
                
                throw NSError(domain: "API", code: httpResponse.statusCode,
                            userInfo: [NSLocalizedDescriptionKey: errorMessage])
            }
        }
        
        do {
            let coverageResponse = try JSONDecoder().decode(AppleCareCoverageResponse.self, from: data)
            print("AppleCare decoded successfully: \(coverageResponse.data.attributes.coverageStatus ?? "nil")")
            return coverageResponse.data
        } catch {
            print("AppleCare JSON decode error: \(error)")
            throw error
        }
    }
    
    // Get assigned MDM server for a device
    func getAssignedServer(deviceId: String, accessToken: String, platform: ApplePlatform) async throws -> String? {
        let url = apiURL(platform: platform, path: "/v1/orgDevices/\(deviceId)/relationships/assignedServer")
        let headers = [
            "Authorization": "Bearer \(accessToken)",
            "Accept": "application/json"
        ]
        
        let (data, response) = try await makeRequest(url: url, headers: headers)
        
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode != 200 {
                return nil
            }
        }
        
        let relationResponse = try JSONDecoder().decode(AssignedServerResponse.self, from: data)
        return relationResponse.data?.id
    }
    
    // Fetch MDM servers
    func fetchMDMServers(accessToken: String, platform: ApplePlatform) async throws -> [MDMServer] {
        let url = apiURL(platform: platform, path: "/v1/mdmServers")
        let headers = [
            "Authorization": "Bearer \(accessToken)",
            "Accept": "application/json"
        ]
        
        let (data, response) = try await makeRequest(url: url, headers: headers)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("MDM Status Code: \(httpResponse.statusCode)")
            if httpResponse.statusCode != 200 {
                print("MDM Response: \(String(data: data, encoding: .utf8) ?? "No data")")
            }
        }
        
        let mdmResponse = try JSONDecoder().decode(MDMServersResponse.self, from: data)
        return mdmResponse.data
    }
    
    // Get devices for MDM server
    func getDevicesForMDM(mdmId: String, accessToken: String, platform: ApplePlatform) async throws -> [String] {
        let url = apiURL(platform: platform, path: "/v1/mdmServers/\(mdmId)/relationships/devices")
        let headers = ["Authorization": "Bearer \(accessToken)"]
        
        let (data, _) = try await makeRequest(url: url, headers: headers)
        let response = try JSONDecoder().decode(RelationshipResponse.self, from: data)
        return response.data.map { $0.id }
    }
    
    // Assign/unassign devices
    func assignDevices(deviceIds: [String], mdmId: String?, accessToken: String, platform: ApplePlatform) async throws -> String {
        let url = apiURL(platform: platform, path: "/v1/orgDeviceActivities")
        
        let activity = DeviceActivity(
            data: DeviceActivity.ActivityData(
                type: "orgDeviceActivities",
                attributes: DeviceActivity.ActivityAttributes(
                    activityType: mdmId != nil ? "ASSIGN_DEVICES" : "UNASSIGN_DEVICES"
                ),
                relationships: DeviceActivity.ActivityRelationships(
                    mdmServer: DeviceActivity.MDMServerRelation(
                        data: DeviceActivity.RelationData(
                            type: "mdmServers",
                            id: mdmId ?? ""
                        )
                    ),
                    devices: DeviceActivity.DevicesRelation(
                        data: deviceIds.map {
                            DeviceActivity.RelationData(type: "orgDevices", id: $0)
                        }
                    )
                )
            )
        )
        
        let headers = [
            "Authorization": "Bearer \(accessToken)",
            "Content-Type": "application/json"
        ]
        let body = try JSONEncoder().encode(activity)
        
        let (data, response) = try await makeRequest(url: url, method: "POST", headers: headers, body: body)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("Assign Status: \(httpResponse.statusCode)")
            if httpResponse.statusCode != 200 && httpResponse.statusCode != 201 {
                print("Assign Error: \(String(data: data, encoding: .utf8) ?? "")")
                throw NSError(domain: "API", code: httpResponse.statusCode)
            }
        }
        
        let activityResponse = try JSONDecoder().decode(ActivityStatusResponse.self, from: data)
        return activityResponse.data.id
    }
    
}


struct DeviceDetailResponse: Codable {
    let data: OrgDevice
}

struct RelationshipResponse: Codable {
    let data: [RelationData]
    
    struct RelationData: Codable {
        let type: String
        let id: String
    }
}

struct AssignedServerResponse: Codable {
    let data: ServerRelationData?
    
    struct ServerRelationData: Codable {
        let type: String
        let id: String
    }
}

// MARK: - Users (ABM only)

extension APIService {
    func fetchUsers(accessToken: String, platform: ApplePlatform) async throws -> [ABMUser] {
        guard platform.supportsUsers else { return [] }
        return try await fetchAllPages(accessToken: accessToken, platform: platform, path: "/v1/users")
    }
    
    func getUser(id: String, accessToken: String, platform: ApplePlatform) async throws -> ABMUser {
        let url = apiURL(platform: platform, path: "/v1/users/\(id)")
        let headers = ["Authorization": "Bearer \(accessToken)", "Accept": "application/json"]
        let (data, _) = try await makeRequest(url: url, headers: headers)
        return try JSONDecoder().decode(ABMUserResponse.self, from: data).data
    }
}

// MARK: - User Groups (ABM only)

extension APIService {
    func fetchUserGroups(accessToken: String, platform: ApplePlatform) async throws -> [ABMUserGroup] {
        guard platform.supportsUserGroups else { return [] }
        return try await fetchAllPages(accessToken: accessToken, platform: platform, path: "/v1/userGroups")
    }
    
    func getUserGroup(id: String, accessToken: String, platform: ApplePlatform) async throws -> ABMUserGroup {
        let url = apiURL(platform: platform, path: "/v1/userGroups/\(id)")
        let headers = ["Authorization": "Bearer \(accessToken)", "Accept": "application/json"]
        let (data, _) = try await makeRequest(url: url, headers: headers)
        return try JSONDecoder().decode(ABMUserGroupResponse.self, from: data).data
    }
    
    func getUserGroupMembers(groupId: String, accessToken: String, platform: ApplePlatform) async throws -> [String] {
        let url = apiURL(platform: platform, path: "/v1/userGroups/\(groupId)/relationships/users")
        let headers = ["Authorization": "Bearer \(accessToken)", "Accept": "application/json"]
        let (data, _) = try await makeRequest(url: url, headers: headers)
        let response = try JSONDecoder().decode(LinkageResponse.self, from: data)
        return response.data.map { $0.id }
    }
}

// MARK: - Apps (ABM only)

extension APIService {
    func fetchApps(accessToken: String, platform: ApplePlatform, contentToken: String? = nil) async throws -> [ABMApp] {
        guard platform.supportsApps else { return [] }
        
        // Try VPP Content Token first (returns all purchased/licensed apps)
        if let token = contentToken, !token.isEmpty {
            if let vppApps = await fetchAppsFromVPP(contentToken: token), !vppApps.isEmpty {
                return vppApps
            }
        }
        
        // Fall back to official Business API (returns Blueprint-assigned apps)
        return try await fetchAllPages(accessToken: accessToken, platform: platform, path: "/v1/apps")
    }
    
    func getApp(id: String, accessToken: String, platform: ApplePlatform) async throws -> ABMApp {
        let url = apiURL(platform: platform, path: "/v1/apps/\(id)")
        let headers = ["Authorization": "Bearer \(accessToken)", "Accept": "application/json"]
        let (data, _) = try await makeRequest(url: url, headers: headers)
        return try JSONDecoder().decode(ABMAppResponse.self, from: data).data
    }
    
    /// Fetches purchased/licensed apps via the VPP / Apps & Books Content Token API,
    /// then enriches them with app metadata from the iTunes Search API.
    private func fetchAppsFromVPP(contentToken: String) async -> [ABMApp]? {
        var allAssets: [VPPAsset] = []
        var pageIndex = 0
        
        // Fetch all VPP asset pages
        repeat {
            guard let url = URL(string: "https://vpp.itunes.apple.com/mdm/v2/assets?productType=App&pageIndex=\(pageIndex)") else { break }
            
            let headers = [
                "Authorization": "Bearer \(contentToken)",
                "Accept": "application/json"
            ]
            
            do {
                let (data, response) = try await makeRequest(url: url, headers: headers, maxRetries: 2)
                guard let http = response as? HTTPURLResponse else { return nil }
                
                print("[VPP API] assets pageIndex=\(pageIndex) -> HTTP \(http.statusCode), \(data.count) bytes")
                
                guard http.statusCode == 200 else {
                    print("[VPP API] Non-200 (\(http.statusCode)), falling back to Business API for apps")
                    if let body = String(data: data, encoding: .utf8) {
                        print("[VPP API] Response: \(body.prefix(500))")
                    }
                    return nil
                }
                
                let decoded = try JSONDecoder().decode(VPPAssetsResponse.self, from: data)
                if let assets = decoded.assets {
                    allAssets.append(contentsOf: assets)
                }
                
                // Check for next page
                if let nextPage = decoded.nextPageIndex {
                    pageIndex = nextPage
                } else {
                    break
                }
            } catch {
                print("[VPP API] Error: \(error.localizedDescription), falling back to Business API for apps")
                return nil
            }
        } while true
        
        guard !allAssets.isEmpty else { return nil }
        print("[VPP API] Fetched \(allAssets.count) app assets")
        
        // Enrich with app metadata from iTunes Search API
        let adamIds = allAssets.map { $0.adamId }
        let itunesLookup = await lookupAppsFromITunes(adamIds: adamIds)
        
        // Merge VPP license data with iTunes metadata
        return allAssets.map { asset in
            let info = itunesLookup[asset.adamId]
            return ABMApp(
                id: asset.adamId,
                type: "apps",
                attributes: ABMApp.AppAttributes(
                    name: info?.trackName,
                    bundleId: info?.bundleId,
                    version: info?.version,
                    supportedOS: asset.supportedPlatforms,
                    appStoreUrl: info?.trackViewUrl,
                    artistName: info?.artistName,
                    deviceFamilies: asset.supportedPlatforms,
                    priceFormatted: info?.formattedPrice,
                    assignedCount: asset.assignedCount,
                    availableCount: asset.availableCount,
                    totalCount: asset.totalCount
                )
            )
        }
    }
    
    /// Batch-lookup app metadata from the public iTunes Search API.
    /// The API supports up to ~200 IDs per request; we chunk accordingly.
    private func lookupAppsFromITunes(adamIds: [String]) async -> [String: ITunesApp] {
        var result: [String: ITunesApp] = [:]
        let chunkSize = 150
        
        for chunk in stride(from: 0, to: adamIds.count, by: chunkSize) {
            let end = min(chunk + chunkSize, adamIds.count)
            let ids = Array(adamIds[chunk..<end])
            let idString = ids.joined(separator: ",")
            
            guard let url = URL(string: "https://itunes.apple.com/lookup?id=\(idString)") else { continue }
            
            do {
                let (data, response) = try await makeRequest(url: url, maxRetries: 2)
                guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                    print("[iTunes Lookup] Non-200 response")
                    continue
                }
                
                let decoded = try JSONDecoder().decode(ITunesLookupResponse.self, from: data)
                for app in decoded.results {
                    if let trackId = app.trackId {
                        result[String(trackId)] = app
                    }
                }
                print("[iTunes Lookup] Resolved \(decoded.results.count) apps from \(ids.count) IDs")
            } catch {
                print("[iTunes Lookup] Error: \(error.localizedDescription)")
            }
        }
        
        return result
    }
}

// MARK: - Packages (ABM only)

extension APIService {
    func fetchPackages(accessToken: String, platform: ApplePlatform) async throws -> [ABMPackage] {
        guard platform.supportsPackages else { return [] }
        return try await fetchAllPages(accessToken: accessToken, platform: platform, path: "/v1/packages")
    }
    
    func getPackage(id: String, accessToken: String, platform: ApplePlatform) async throws -> ABMPackage {
        let url = apiURL(platform: platform, path: "/v1/packages/\(id)")
        let headers = ["Authorization": "Bearer \(accessToken)", "Accept": "application/json"]
        let (data, _) = try await makeRequest(url: url, headers: headers)
        return try JSONDecoder().decode(ABMPackageResponse.self, from: data).data
    }
}

// MARK: - Blueprints (ABM only)

extension APIService {
    func fetchBlueprints(accessToken: String, platform: ApplePlatform) async throws -> [Blueprint] {
        guard platform.supportsBlueprints else { return [] }
        return try await fetchAllPages(accessToken: accessToken, platform: platform, path: "/v1/blueprints")
    }
    
    func getBlueprint(id: String, accessToken: String, platform: ApplePlatform) async throws -> Blueprint {
        let url = apiURL(platform: platform, path: "/v1/blueprints/\(id)")
        let headers = ["Authorization": "Bearer \(accessToken)", "Accept": "application/json"]
        let (data, _) = try await makeRequest(url: url, headers: headers)
        return try JSONDecoder().decode(BlueprintResponse.self, from: data).data
    }
    
    func createBlueprint(name: String, accessToken: String, platform: ApplePlatform) async throws -> Blueprint {
        let url = apiURL(platform: platform, path: "/v1/blueprints")
        let headers = ["Authorization": "Bearer \(accessToken)", "Content-Type": "application/json", "Accept": "application/json"]
        let body = try JSONEncoder().encode(BlueprintCreateRequest(name: name))
        let (data, response) = try await makeRequest(url: url, method: "POST", headers: headers, body: body)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 && http.statusCode != 201 {
            let msg = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "API", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "Create blueprint failed (\(http.statusCode)): \(msg)"])
        }
        return try JSONDecoder().decode(BlueprintResponse.self, from: data).data
    }
    
    func updateBlueprint(id: String, name: String, accessToken: String, platform: ApplePlatform) async throws -> Blueprint {
        let url = apiURL(platform: platform, path: "/v1/blueprints/\(id)")
        let headers = ["Authorization": "Bearer \(accessToken)", "Content-Type": "application/json", "Accept": "application/json"]
        let body = try JSONEncoder().encode(BlueprintUpdateRequest(id: id, name: name))
        let (data, response) = try await makeRequest(url: url, method: "PATCH", headers: headers, body: body)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            let msg = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "API", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "Update blueprint failed (\(http.statusCode)): \(msg)"])
        }
        return try JSONDecoder().decode(BlueprintResponse.self, from: data).data
    }
    
    func deleteBlueprint(id: String, accessToken: String, platform: ApplePlatform) async throws {
        let url = apiURL(platform: platform, path: "/v1/blueprints/\(id)")
        let headers = ["Authorization": "Bearer \(accessToken)", "Accept": "application/json"]
        let (data, response) = try await makeRequest(url: url, method: "DELETE", headers: headers)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 && http.statusCode != 204 {
            let msg = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "API", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "Delete blueprint failed (\(http.statusCode)): \(msg)"])
        }
    }
    
    func getBlueprintLinkages(blueprintId: String, relation: String, accessToken: String, platform: ApplePlatform) async throws -> [String] {
        let url = apiURL(platform: platform, path: "/v1/blueprints/\(blueprintId)/relationships/\(relation)")
        let headers = ["Authorization": "Bearer \(accessToken)", "Accept": "application/json"]
        let (data, _) = try await makeRequest(url: url, headers: headers)
        let response = try JSONDecoder().decode(LinkageResponse.self, from: data)
        return response.data.map { $0.id }
    }
    
    func addBlueprintLinkages(blueprintId: String, relation: String, type: String, ids: [String], accessToken: String, platform: ApplePlatform) async throws {
        let url = apiURL(platform: platform, path: "/v1/blueprints/\(blueprintId)/relationships/\(relation)")
        let headers = ["Authorization": "Bearer \(accessToken)", "Content-Type": "application/json", "Accept": "application/json"]
        let body = try JSONEncoder().encode(LinkageRequest(type: type, ids: ids))
        let (data, response) = try await makeRequest(url: url, method: "POST", headers: headers, body: body)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 && http.statusCode != 204 {
            let msg = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "API", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "Add linkages failed (\(http.statusCode)): \(msg)"])
        }
    }
    
    func removeBlueprintLinkages(blueprintId: String, relation: String, type: String, ids: [String], accessToken: String, platform: ApplePlatform) async throws {
        let url = apiURL(platform: platform, path: "/v1/blueprints/\(blueprintId)/relationships/\(relation)")
        let headers = ["Authorization": "Bearer \(accessToken)", "Content-Type": "application/json", "Accept": "application/json"]
        let body = try JSONEncoder().encode(LinkageRequest(type: type, ids: ids))
        let (data, response) = try await makeRequest(url: url, method: "DELETE", headers: headers, body: body)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 && http.statusCode != 204 {
            let msg = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "API", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "Remove linkages failed (\(http.statusCode)): \(msg)"])
        }
    }
}

// MARK: - Configurations (ABM only)

extension APIService {
    func fetchConfigurations(accessToken: String, platform: ApplePlatform) async throws -> [ABMConfiguration] {
        guard platform.supportsConfigurations else { return [] }
        return try await fetchAllPages(accessToken: accessToken, platform: platform, path: "/v1/configurations")
    }
    
    func getConfiguration(id: String, accessToken: String, platform: ApplePlatform) async throws -> ABMConfiguration {
        let url = apiURL(platform: platform, path: "/v1/configurations/\(id)")
        let headers = ["Authorization": "Bearer \(accessToken)", "Accept": "application/json"]
        let (data, _) = try await makeRequest(url: url, headers: headers)
        return try JSONDecoder().decode(ABMConfigurationResponse.self, from: data).data
    }
    
    func createConfiguration(name: String, accessToken: String, platform: ApplePlatform) async throws -> ABMConfiguration {
        let url = apiURL(platform: platform, path: "/v1/configurations")
        let headers = ["Authorization": "Bearer \(accessToken)", "Content-Type": "application/json", "Accept": "application/json"]
        let body = try JSONEncoder().encode(ConfigurationCreateRequest(name: name))
        let (data, response) = try await makeRequest(url: url, method: "POST", headers: headers, body: body)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 && http.statusCode != 201 {
            let msg = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "API", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "Create configuration failed (\(http.statusCode)): \(msg)"])
        }
        return try JSONDecoder().decode(ABMConfigurationResponse.self, from: data).data
    }
    
    func updateConfiguration(id: String, name: String, accessToken: String, platform: ApplePlatform) async throws -> ABMConfiguration {
        let url = apiURL(platform: platform, path: "/v1/configurations/\(id)")
        let headers = ["Authorization": "Bearer \(accessToken)", "Content-Type": "application/json", "Accept": "application/json"]
        let body = try JSONEncoder().encode(ConfigurationUpdateRequest(id: id, name: name))
        let (data, response) = try await makeRequest(url: url, method: "PATCH", headers: headers, body: body)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            let msg = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "API", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "Update configuration failed (\(http.statusCode)): \(msg)"])
        }
        return try JSONDecoder().decode(ABMConfigurationResponse.self, from: data).data
    }
    
    func deleteConfiguration(id: String, accessToken: String, platform: ApplePlatform) async throws {
        let url = apiURL(platform: platform, path: "/v1/configurations/\(id)")
        let headers = ["Authorization": "Bearer \(accessToken)", "Accept": "application/json"]
        let (data, response) = try await makeRequest(url: url, method: "DELETE", headers: headers)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 && http.statusCode != 204 {
            let msg = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "API", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "Delete configuration failed (\(http.statusCode)): \(msg)"])
        }
    }
}

// MARK: - Audit Events (ABM only)

extension APIService {
    func fetchAuditEvents(accessToken: String, platform: ApplePlatform, startDateTime: String? = nil, endDateTime: String? = nil) async throws -> [AuditEvent] {
        guard platform.supportsAuditEvents else { return [] }
        var path = "/v1/auditEvents"
        var queryItems: [String] = []
        if let start = startDateTime {
            queryItems.append("filter[startDateTime]=\(start)")
        }
        if let end = endDateTime {
            queryItems.append("filter[endDateTime]=\(end)")
        }
        if !queryItems.isEmpty {
            path += "?" + queryItems.joined(separator: "&")
        }
        return try await fetchAllPages(accessToken: accessToken, platform: platform, path: path)
    }
}

// MARK: - MDM Enrolled Devices (ABM only)

extension APIService {
    func fetchMdmEnrolledDevices(accessToken: String, platform: ApplePlatform) async throws -> [MdmEnrolledDevice] {
        guard platform.supportsMdmEnrolledDevices else { return [] }
        return try await fetchAllPages(accessToken: accessToken, platform: platform, path: "/v1/mdmDevices")
    }
    
    func getMdmEnrolledDeviceDetail(id: String, accessToken: String, platform: ApplePlatform) async throws -> MdmEnrolledDeviceDetail {
        let url = apiURL(platform: platform, path: "/v1/mdmDevices/\(id)")
        let headers = ["Authorization": "Bearer \(accessToken)", "Accept": "application/json"]
        let (data, _) = try await makeRequest(url: url, headers: headers)
        return try JSONDecoder().decode(MdmEnrolledDeviceDetailResponse.self, from: data).data
    }
}

// MARK: - Generic Paginated Fetch

extension APIService {
    /// Fetches all pages of a paginated JSON:API endpoint, returning decoded items.
    private func fetchAllPages<T: Decodable>(accessToken: String, platform: ApplePlatform, path: String) async throws -> [T] {
        var all: [T] = []
        var nextURL: String? = path.hasPrefix("http") ? path : apiURL(platform: platform, path: path).absoluteString
        
        while let urlString = nextURL {
            guard let url = URL(string: urlString) else { break }
            let headers = ["Authorization": "Bearer \(accessToken)", "Accept": "application/json"]
            let (data, response) = try await makeRequest(url: url, headers: headers)
            
            if let http = response as? HTTPURLResponse {
                if http.statusCode != 200 {
                    let msg = String(data: data, encoding: .utf8) ?? ""
                    throw NSError(domain: "API", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "API returned \(http.statusCode): \(msg)"])
                }
            }
            
            // Debug logging for apps endpoint
            if path.contains("/v1/apps") {
                let rawResponse = String(data: data, encoding: .utf8) ?? "No data"
                print("[fetchAllPages] Raw /v1/apps response: \(rawResponse.prefix(500))")
            }
            
            let page = try JSONDecoder().decode(GenericPageResponse<T>.self, from: data)
            all.append(contentsOf: page.data)
            nextURL = page.links?.next
        }
        print("[fetchAllPages] \(path) -> \(all.count) total items")
        return all
    }
}

/// Generic page response for JSON:API style paginated endpoints.
private struct GenericPageResponse<T: Decodable>: Decodable {
    let data: [T]
    let links: PagedLinks?
}
