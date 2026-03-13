//
//  JamfAPIService.swift
//  ABMate
//
//  Jamf Pro API client using OAuth 2.0 Client Credentials.
//  Supports computer and mobile device inventory lookup & purchasing updates.
//

import Foundation

enum JamfAPIError: LocalizedError {
    case authenticationFailed(String)
    case notFound(String)
    case apiError(Int, String)
    case noToken
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .authenticationFailed(let detail):
            return "Jamf authentication failed: \(detail)"
        case .notFound(let detail):
            return detail
        case .apiError(let code, let detail):
            return "Jamf API error (\(code)): \(detail)"
        case .noToken:
            return "No Jamf access token. Connect to Jamf Pro first."
        case .invalidURL:
            return "Invalid Jamf Pro URL."
        }
    }
}

class JamfAPIService {
    private var accessToken: String?
    private var tokenExpiry: Date?
    private var baseURL: String = ""

    /// Whether we have a valid (non-expired) token
    var isAuthenticated: Bool {
        guard let expiry = tokenExpiry else { return false }
        return accessToken != nil && expiry > Date()
    }

    // MARK: - Authentication

    /// Authenticate with Jamf Pro using OAuth 2.0 Client Credentials
    @discardableResult
    func authenticate(baseURL: String, clientId: String, clientSecret: String) async throws -> String {
        // Normalize the URL
        var normalizedURL = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalizedURL.hasSuffix("/") {
            normalizedURL = String(normalizedURL.dropLast())
        }
        // Ensure https://
        if !normalizedURL.lowercased().hasPrefix("http") {
            normalizedURL = "https://\(normalizedURL)"
        }
        self.baseURL = normalizedURL

        guard let url = URL(string: "\(normalizedURL)/api/oauth/token") else {
            throw JamfAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyParams = [
            "client_id": clientId,
            "client_secret": clientSecret,
            "grant_type": "client_credentials"
        ]

        let bodyString = bodyParams
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }
            .joined(separator: "&")

        request.httpBody = bodyString.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode != 200 {
                let body = String(data: data, encoding: .utf8) ?? "No response"
                print("Jamf Auth Error (\(httpResponse.statusCode)): \(body)")
                throw JamfAPIError.authenticationFailed("HTTP \(httpResponse.statusCode) — check your URL, Client ID, and Client Secret.")
            }
        }

        let tokenResponse = try JSONDecoder().decode(JamfTokenResponse.self, from: data)
        self.accessToken = tokenResponse.accessToken
        self.tokenExpiry = Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn))

        print("Jamf Pro authenticated successfully. Token expires in \(tokenResponse.expiresIn)s.")
        return tokenResponse.accessToken
    }

    /// Get a valid token, refreshing if needed
    func getToken(baseURL: String, clientId: String, clientSecret: String) async throws -> String {
        if let token = accessToken, let expiry = tokenExpiry, expiry > Date().addingTimeInterval(30) {
            return token
        }
        return try await authenticate(baseURL: baseURL, clientId: clientId, clientSecret: clientSecret)
    }

    /// Clear stored token (for disconnect)
    func clearToken() {
        accessToken = nil
        tokenExpiry = nil
        baseURL = ""
    }

    // MARK: - Computer Inventory

    /// Search for a computer by serial number
    func findComputerBySerial(_ serial: String, token: String) async throws -> JamfComputer? {
        let encodedFilter = "hardware.serialNumber==\"\(serial)\"".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(baseURL)/api/v1/computers-inventory?section=GENERAL&section=HARDWARE&section=PURCHASING&page=0&page-size=1&filter=\(encodedFilter)"

        guard let url = URL(string: urlString) else {
            throw JamfAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            print("Jamf Computer Search (\(serial)): HTTP \(httpResponse.statusCode)")
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                throw JamfAPIError.authenticationFailed("Token expired or insufficient permissions.")
            }
            if httpResponse.statusCode != 200 {
                let body = String(data: data, encoding: .utf8) ?? ""
                throw JamfAPIError.apiError(httpResponse.statusCode, body)
            }
        }

        let searchResponse = try JSONDecoder().decode(JamfComputerSearchResponse.self, from: data)
        return searchResponse.results.first
    }

    /// Update purchasing info for a computer
    func updateComputerPurchasing(id: String, purchasing: JamfPurchasing, token: String) async throws {
        guard let url = URL(string: "\(baseURL)/api/v1/computers-inventory-detail/\(id)") else {
            throw JamfAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let updatePayload = JamfComputerDetailUpdate(purchasing: purchasing)
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(updatePayload)

        // Debug: print what we're sending
        if let bodyString = String(data: request.httpBody!, encoding: .utf8) {
            print("Jamf PATCH body: \(bodyString)")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            print("Jamf Computer Update (\(id)): HTTP \(httpResponse.statusCode)")
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                throw JamfAPIError.authenticationFailed("Token expired or insufficient permissions.")
            }
            if httpResponse.statusCode != 200 && httpResponse.statusCode != 204 {
                let body = String(data: data, encoding: .utf8) ?? ""
                throw JamfAPIError.apiError(httpResponse.statusCode, body)
            }
        }
    }

    // MARK: - Mobile Device Inventory

    /// Search for a mobile device by serial number
    func findMobileDeviceBySerial(_ serial: String, token: String) async throws -> JamfMobileDevice? {
        let encodedFilter = "serialNumber==\"\(serial)\"".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(baseURL)/api/v2/mobile-devices?page=0&page-size=1&filter=\(encodedFilter)"

        guard let url = URL(string: urlString) else {
            throw JamfAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            print("Jamf Mobile Search (\(serial)): HTTP \(httpResponse.statusCode)")
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                throw JamfAPIError.authenticationFailed("Token expired or insufficient permissions.")
            }
            if httpResponse.statusCode != 200 {
                let body = String(data: data, encoding: .utf8) ?? ""
                throw JamfAPIError.apiError(httpResponse.statusCode, body)
            }
        }

        let searchResponse = try JSONDecoder().decode(JamfMobileDeviceSearchResponse.self, from: data)
        return searchResponse.results.first
    }

    /// Get mobile device detail (includes purchasing)
    func getMobileDeviceDetail(id: String, token: String) async throws -> JamfMobileDeviceDetail {
        guard let url = URL(string: "\(baseURL)/api/v2/mobile-devices/\(id)/detail") else {
            throw JamfAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode != 200 {
                let body = String(data: data, encoding: .utf8) ?? ""
                throw JamfAPIError.apiError(httpResponse.statusCode, body)
            }
        }

        return try JSONDecoder().decode(JamfMobileDeviceDetail.self, from: data)
    }

    /// Update purchasing info for a mobile device
    func updateMobileDevicePurchasing(id: String, purchasing: JamfPurchasing, token: String) async throws {
        guard let url = URL(string: "\(baseURL)/api/v2/mobile-devices/\(id)") else {
            throw JamfAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let updatePayload = JamfMobileDeviceUpdate(purchasing: purchasing)
        request.httpBody = try JSONEncoder().encode(updatePayload)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            print("Jamf Mobile Update (\(id)): HTTP \(httpResponse.statusCode)")
            if httpResponse.statusCode != 200 && httpResponse.statusCode != 204 {
                let body = String(data: data, encoding: .utf8) ?? ""
                throw JamfAPIError.apiError(httpResponse.statusCode, body)
            }
        }
    }

    // MARK: - Unified Device Lookup

    /// Find a device in Jamf Pro by serial — tries computers first, then mobile devices.
    /// Returns a unified JamfDeviceMatch or nil if not found in either.
    func findDeviceBySerial(_ serial: String, token: String) async throws -> JamfDeviceMatch? {
        // Try computers first
        if let computer = try await findComputerBySerial(serial, token: token) {
            let purchasing: JamfPurchasing? = computer.purchasing
            return JamfDeviceMatch(
                id: computer.id,
                name: computer.general?.name ?? "Unknown",
                serial: computer.hardware?.serialNumber ?? serial,
                model: computer.hardware?.model ?? "Unknown",
                deviceType: .computer,
                currentPurchasing: purchasing
            )
        }

        // Then try mobile devices
        if let mobile = try await findMobileDeviceBySerial(serial, token: token) {
            // Fetch detail to get purchasing info
            let detail = try? await getMobileDeviceDetail(id: mobile.id, token: token)
            return JamfDeviceMatch(
                id: mobile.id,
                name: mobile.name ?? "Unknown",
                serial: mobile.serialNumber ?? serial,
                model: mobile.model ?? "Unknown",
                deviceType: .mobileDevice,
                currentPurchasing: detail?.purchasing
            )
        }

        return nil
    }

    /// Push purchasing data to the correct Jamf endpoint based on device type
    func updateDevicePurchasing(match: JamfDeviceMatch, purchasing: JamfPurchasing, token: String) async throws {
        switch match.deviceType {
        case .computer:
            try await updateComputerPurchasing(id: match.id, purchasing: purchasing, token: token)
        case .mobileDevice:
            try await updateMobileDevicePurchasing(id: match.id, purchasing: purchasing, token: token)
        }
    }
}
