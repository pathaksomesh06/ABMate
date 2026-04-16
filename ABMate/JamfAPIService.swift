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
        // Strategy: Go straight to Classic XML API which is the only proven working endpoint.
        // v2/v1 JSON endpoints consistently fail (405/400/404) for mobile purchasing updates.

        guard let classicURL = URL(string: "\(baseURL)/JSSResource/mobiledevices/id/\(id)") else {
            throw JamfAPIError.invalidURL
        }

        var classicRequest = URLRequest(url: classicURL)
        classicRequest.httpMethod = "PUT"
        classicRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        classicRequest.setValue("application/xml", forHTTPHeaderField: "Content-Type")
        classicRequest.setValue("application/xml", forHTTPHeaderField: "Accept")

        var xml = "<mobile_device><purchasing>"
        xml += "<is_purchased>\((purchasing.purchased ?? false) ? "true" : "false")</is_purchased>"
        xml += "<is_leased>\((purchasing.leased ?? false) ? "true" : "false")</is_leased>"
        if let po = purchasing.poNumber { xml += "<po_number>\(escapeXML(po))</po_number>" }
        if let vendor = purchasing.vendor { xml += "<vendor>\(escapeXML(vendor))</vendor>" }
        if let poDate = purchasing.poDate { xml += "<po_date>\(escapeXML(poDate))</po_date>" }
        if let warrantyDate = purchasing.warrantyDate { xml += "<warranty_expires>\(escapeXML(warrantyDate))</warranty_expires>" }
        if let appleCareId = purchasing.appleCareId { xml += "<applecare_id>\(escapeXML(appleCareId))</applecare_id>" }
        if let leaseDate = purchasing.leaseDate { xml += "<lease_expires>\(escapeXML(leaseDate))</lease_expires>" }
        if let price = purchasing.purchasePrice { xml += "<purchase_price>\(escapeXML(price))</purchase_price>" }
        if let life = purchasing.lifeExpectancy { xml += "<life_expectancy>\(life)</life_expectancy>" }
        if let account = purchasing.purchasingAccount { xml += "<purchasing_account>\(escapeXML(account))</purchasing_account>" }
        if let contact = purchasing.purchasingContact { xml += "<purchasing_contact>\(escapeXML(contact))</purchasing_contact>" }
        xml += "</purchasing></mobile_device>"

        classicRequest.httpBody = xml.data(using: .utf8)

        let (data, resp) = try await URLSession.shared.data(for: classicRequest)
        let status = (resp as? HTTPURLResponse)?.statusCode ?? 0

        if status == 200 || status == 201 { return }

        let body = String(data: data, encoding: .utf8) ?? ""
        throw JamfAPIError.apiError(status, "Classic mobile update failed. HTTP \(status): \(body.prefix(500))")
    }

    /// Escape special characters for XML values
    private func escapeXML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
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

    // MARK: - Bulk Fetch (Paginated)

    /// Fetch ALL computers from Jamf Pro (paginated). Returns a dict of serial → JamfBulkDevice.
    func fetchAllComputers(token: String, onProgress: @Sendable (Int, Int) -> Void = { _, _ in }) async throws -> [String: JamfBulkDevice] {
        var result: [String: JamfBulkDevice] = [:]
        var page = 0
        let pageSize = 100
        var totalCount = 0

        repeat {
            let urlString = "\(baseURL)/api/v1/computers-inventory?section=HARDWARE&section=GENERAL&section=PURCHASING&page=\(page)&page-size=\(pageSize)"
            guard let url = URL(string: urlString) else { throw JamfAPIError.invalidURL }

            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Accept")

            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                let body = String(data: data, encoding: .utf8) ?? ""
                throw JamfAPIError.apiError(httpResponse.statusCode, body)
            }

            let searchResponse = try JSONDecoder().decode(JamfComputerSearchResponse.self, from: data)
            totalCount = searchResponse.totalCount

            for computer in searchResponse.results {
                if let serial = computer.hardware?.serialNumber, !serial.isEmpty {
                    result[serial.uppercased()] = JamfBulkDevice(
                        id: computer.id,
                        name: computer.general?.name ?? "Unknown",
                        serial: serial,
                        model: computer.hardware?.model ?? "Unknown",
                        deviceType: .computer,
                        currentPONumber: computer.purchasing?.poNumber,
                        currentVendor: computer.purchasing?.vendor,
                        currentWarrantyDate: computer.purchasing?.warrantyDate,
                        currentAppleCareId: computer.purchasing?.appleCareId
                    )
                }
            }

            onProgress(result.count, totalCount)
            page += 1
        } while result.count < totalCount && page < 200 // safety cap

        print("Jamf bulk fetch: \(result.count) computers")
        return result
    }

    /// Fetch ALL mobile devices from Jamf Pro (paginated). Returns a dict of serial → JamfBulkDevice.
    func fetchAllMobileDevices(token: String, onProgress: @Sendable (Int, Int) -> Void = { _, _ in }) async throws -> [String: JamfBulkDevice] {
        var result: [String: JamfBulkDevice] = [:]
        var page = 0
        let pageSize = 100
        var totalCount = 0

        repeat {
            let urlString = "\(baseURL)/api/v2/mobile-devices?page=\(page)&page-size=\(pageSize)"
            guard let url = URL(string: urlString) else { throw JamfAPIError.invalidURL }

            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Accept")

            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                let body = String(data: data, encoding: .utf8) ?? ""
                throw JamfAPIError.apiError(httpResponse.statusCode, body)
            }

            let searchResponse = try JSONDecoder().decode(JamfMobileDeviceSearchResponse.self, from: data)
            totalCount = searchResponse.totalCount

            for device in searchResponse.results {
                if let serial = device.serialNumber, !serial.isEmpty {
                    result[serial.uppercased()] = JamfBulkDevice(
                        id: device.id,
                        name: device.name ?? "Unknown",
                        serial: serial,
                        model: device.model ?? "Unknown",
                        deviceType: .mobileDevice
                    )
                }
            }

            onProgress(result.count, totalCount)
            page += 1
        } while result.count < totalCount && page < 200

        print("Jamf bulk fetch: \(result.count) mobile devices")
        return result
    }

    /// Fetch purchasing data for mobile devices via Classic API (v2 list doesn't include purchasing).
    /// Updates the provided dict in-place with purchasing fields. Uses concurrent requests for speed.
    func fetchMobilePurchasingData(
        devices: inout [String: JamfBulkDevice],
        token: String,
        onProgress: @Sendable (Int, Int) -> Void = { _, _ in }
    ) async {
        let mobileDevices = devices.filter { $0.value.deviceType == .mobileDevice }
        let total = mobileDevices.count
        guard total > 0 else { return }

        // Capture baseURL locally to avoid capturing non-Sendable self in addTask closures
        let capturedBaseURL = self.baseURL

        // Fetch in batches of 10 concurrent requests
        let batchSize = 10
        let entries = Array(mobileDevices)
        var fetched = 0

        for batchStart in stride(from: 0, to: entries.count, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, entries.count)
            let batch = entries[batchStart..<batchEnd]

            await withTaskGroup(of: (String, JamfPurchasing?).self) { group in
                for (serial, device) in batch {
                    group.addTask {
                        do {
                            guard let url = URL(string: "\(capturedBaseURL)/JSSResource/mobiledevices/id/\(device.id)/subset/Purchasing") else {
                                return (serial, nil)
                            }
                            var request = URLRequest(url: url)
                            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                            request.setValue("application/json", forHTTPHeaderField: "Accept")

                            let (data, response) = try await URLSession.shared.data(for: request)
                            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
                            guard status == 200 else { return (serial, nil) }

                            // Classic API with Accept: application/json returns JSON
                            struct ClassicMobileResponse: Codable {
                                let mobile_device: ClassicMobileDevice?
                                struct ClassicMobileDevice: Codable {
                                    let purchasing: ClassicPurchasing?
                                }
                                struct ClassicPurchasing: Codable {
                                    let is_purchased: Bool?
                                    let is_leased: Bool?
                                    let po_number: String?
                                    let vendor: String?
                                    let purchase_price: String?
                                    let purchasing_account: String?
                                    let purchasing_contact: String?
                                    let po_date: String?
                                    let po_date_epoch: Int?
                                    let po_date_utc: String?
                                    let warranty_expires: String?
                                    let warranty_expires_epoch: Int?
                                    let warranty_expires_utc: String?
                                    let applecare_id: String?
                                    let lease_expires: String?
                                    let life_expectancy: Int?
                                }
                            }

                            let decoded = try JSONDecoder().decode(ClassicMobileResponse.self, from: data)
                            if let p = decoded.mobile_device?.purchasing {
                                let purchasing = JamfPurchasing(
                                    purchased: p.is_purchased,
                                    leased: p.is_leased,
                                    poNumber: p.po_number,
                                    poDate: p.po_date,
                                    vendor: p.vendor,
                                    warrantyDate: p.warranty_expires,
                                    appleCareId: p.applecare_id,
                                    leaseDate: p.lease_expires,
                                    purchasePrice: p.purchase_price,
                                    lifeExpectancy: p.life_expectancy,
                                    purchasingAccount: p.purchasing_account,
                                    purchasingContact: p.purchasing_contact
                                )
                                return (serial, purchasing)
                            }
                            return (serial, nil)
                        } catch {
                            return (serial, nil)
                        }
                    }
                }

                for await (serial, purchasing) in group {
                    if let purchasing = purchasing {
                        devices[serial]?.currentPONumber = purchasing.poNumber
                        devices[serial]?.currentVendor = purchasing.vendor
                        devices[serial]?.currentWarrantyDate = purchasing.warrantyDate
                        devices[serial]?.currentAppleCareId = purchasing.appleCareId
                    }
                    fetched += 1
                }
            }

            onProgress(fetched, total)
        }
    }

    /// Fetch ALL Jamf devices (computers + mobile) into a single serial → device dict.
    func fetchAllDevices(token: String, onProgress: @Sendable (String) -> Void = { _ in }) async throws -> [String: JamfBulkDevice] {
        onProgress("Fetching computers from Jamf Pro...")
        var allDevices = try await fetchAllComputers(token: token)

        onProgress("Fetching mobile devices from Jamf Pro...")
        let mobileDevices = try await fetchAllMobileDevices(token: token)

        // Merge — mobile devices won't collide since serials are unique
        allDevices.merge(mobileDevices) { existing, _ in existing }

        onProgress("Found \(allDevices.count) total devices in Jamf Pro.")
        return allDevices
    }
}
