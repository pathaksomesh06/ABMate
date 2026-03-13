//
//  ABMViewModel.swift
//  ABMate
//
//  © Created by Somesh Pathak on 23/06/2025.
//

import Foundation
import SwiftUI

@MainActor
class ABMViewModel: ObservableObject {
    @Published var devices: [OrgDevice] = []
    @Published var mdmServers: [MDMServer] = []
    @Published var activityStatus: ActivityStatusResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var statusMessage: String?
    @Published var lastActivityId: String?

    // Credentials
    @Published var clientId = ""
    @Published var keyId = ""
    @Published var privateKey = ""

    // Connection Profiles
    @Published var savedProfiles: [ConnectionProfile] = []
    @Published var activeProfileId: UUID?

    // MARK: - Jamf Pro Connection
    @Published var jamfURL = ""
    @Published var jamfClientId = ""
    @Published var jamfClientSecret = ""
    @Published var jamfSavedProfiles: [JamfConnectionProfile] = []
    @Published var activeJamfProfileId: UUID?
    @Published var isJamfConnected = false
    @Published var jamfStatusMessage: String?
    @Published var jamfErrorMessage: String?
    @Published var isJamfLoading = false

    let jamfAPIService = JamfAPIService()

    var activeJamfProfileName: String? {
        jamfSavedProfiles.first(where: { $0.id == activeJamfProfileId })?.name
    }

    var activeProfileName: String? {
        savedProfiles.first(where: { $0.id == activeProfileId })?.name
    }

    /// Whether we have an active JWT and have fetched data
    var isConnected: Bool {
        clientAssertion != nil && (!devices.isEmpty || !mdmServers.isEmpty)
    }

    internal let apiService = APIService()
    internal var clientAssertion: String?
    
    // Generate JWT
    func generateJWT() {
        isLoading = true
        errorMessage = nil
        statusMessage = nil
        
        Task {
            do {
                let credentials = APICredentials(
                    clientId: clientId,
                    keyId: keyId,
                    privateKey: privateKey
                )
                
                clientAssertion = try JWTGenerator.createClientAssertion(credentials: credentials)
                statusMessage = "JWT generated successfully"
                saveCredentials()
            } catch {
                errorMessage = "JWT Error: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
    
    // Fetch devices
    func fetchDevices() {
        guard let assertion = clientAssertion else {
            errorMessage = "Generate JWT first"
            return
        }
        
        isLoading = true
        errorMessage = nil
        statusMessage = nil
        
        Task {
            do {
                let token = try await apiService.getAccessToken(
                    clientAssertion: assertion,
                    clientId: clientId
                )
                
                devices = try await apiService.fetchDevices(accessToken: token)
                statusMessage = "Fetched \(devices.count) devices"
            } catch {
                errorMessage = "API Error: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
    
    // Connect to ABM (with one automatic retry on transient network errors)
    func connectToABM() {
        guard let assertion = clientAssertion else {
            errorMessage = "Generate JWT first"
            return
        }

        isLoading = true
        errorMessage = nil
        statusMessage = nil

        Task {
            var lastError: Error?

            for attempt in 1...2 {
                do {
                    let token = try await apiService.getAccessToken(
                        clientAssertion: assertion,
                        clientId: clientId
                    )

                    print("Successfully obtained access token. Fetching data...")

                    // Fetch devices and servers — only replace on success
                    let fetchedDevices = try await apiService.fetchDevices(accessToken: token)
                    print("Successfully fetched \(fetchedDevices.count) devices.")

                    let fetchedServers = try await apiService.fetchMDMServers(accessToken: token)
                    print("Successfully fetched \(fetchedServers.count) servers.")

                    devices = fetchedDevices
                    mdmServers = fetchedServers

                    statusMessage = "Connected to ABM. Fetched \(devices.count) devices and \(mdmServers.count) servers."
                    lastError = nil
                    break
                } catch let error as NSError where error.domain == NSURLErrorDomain && error.code == -1005 {
                    lastError = error
                    if attempt == 1 {
                        print("Network connection lost, retrying in 3s...")
                        statusMessage = "Connection interrupted, retrying..."
                        try? await Task.sleep(nanoseconds: 3_000_000_000)
                    }
                } catch {
                    lastError = error
                    break
                }
            }

            if let error = lastError {
                print("Error during ABM connection: \(error)")
                statusMessage = nil
                errorMessage = "ABM Connection Error: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }

    // Save credentials to UserDefaults
    private func saveCredentials() {
        UserDefaults.standard.set(clientId, forKey: "clientId")
        UserDefaults.standard.set(keyId, forKey: "keyId")
    }

    // Load saved credentials
    func loadCredentials() {
        clientId = UserDefaults.standard.string(forKey: "clientId") ?? ""
        keyId = UserDefaults.standard.string(forKey: "keyId") ?? ""
        loadProfiles()
        loadJamfProfiles()
    }

    // MARK: - Connection Profiles

    func saveProfile(name: String) {
        let profile = ConnectionProfile(
            name: name,
            clientId: clientId,
            keyId: keyId,
            privateKey: privateKey
        )

        // Replace if a profile with the same name exists
        if let index = savedProfiles.firstIndex(where: { $0.name == name }) {
            // Clean up old Keychain entry if UUID changed
            let oldId = savedProfiles[index].id
            if oldId != profile.id {
                KeychainHelper.deletePrivateKey(forProfileId: oldId)
            }
            savedProfiles[index] = profile
        } else {
            savedProfiles.append(profile)
        }

        // Store private key securely in Keychain
        KeychainHelper.savePrivateKey(privateKey, forProfileId: profile.id)

        activeProfileId = profile.id
        persistProfiles()
    }

    func switchToProfile(_ profile: ConnectionProfile) {
        clientId = profile.clientId
        keyId = profile.keyId
        privateKey = profile.privateKey
        activeProfileId = profile.id

        // Reset connection state when switching
        clientAssertion = nil
        devices = []
        mdmServers = []
        statusMessage = nil
        errorMessage = nil
        lastActivityId = nil

        saveCredentials()
        UserDefaults.standard.set(profile.id.uuidString, forKey: "activeProfileId")
    }

    func deleteProfile(_ profile: ConnectionProfile) {
        KeychainHelper.deletePrivateKey(forProfileId: profile.id)
        savedProfiles.removeAll { $0.id == profile.id }
        if activeProfileId == profile.id {
            activeProfileId = nil
        }
        persistProfiles()
    }

    private func persistProfiles() {
        if let data = try? JSONEncoder().encode(savedProfiles) {
            UserDefaults.standard.set(data, forKey: "connectionProfiles")
        }
        if let id = activeProfileId {
            UserDefaults.standard.set(id.uuidString, forKey: "activeProfileId")
        }
    }

    private func loadProfiles() {
        if let data = UserDefaults.standard.data(forKey: "connectionProfiles"),
           var profiles = try? JSONDecoder().decode([ConnectionProfile].self, from: data) {

            // Migrate: check if old JSON has privateKey that hasn't been moved to Keychain yet
            var needsResave = false
            if let rawArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                for (i, rawProfile) in rawArray.enumerated() where i < profiles.count {
                    if let legacyKey = rawProfile["privateKey"] as? String, !legacyKey.isEmpty {
                        // Old format had the key in JSON — migrate it to Keychain
                        if KeychainHelper.readPrivateKey(forProfileId: profiles[i].id) == nil {
                            KeychainHelper.savePrivateKey(legacyKey, forProfileId: profiles[i].id)
                            profiles[i].privateKey = legacyKey
                            needsResave = true
                        }
                    }
                }
            }

            // Hydrate private keys from Keychain
            for i in profiles.indices {
                if profiles[i].privateKey.isEmpty,
                   let key = KeychainHelper.readPrivateKey(forProfileId: profiles[i].id) {
                    profiles[i].privateKey = key
                }
            }
            savedProfiles = profiles

            // Re-persist to strip privateKey from UserDefaults JSON after migration
            if needsResave {
                persistProfiles()
            }
        }
        if let idString = UserDefaults.standard.string(forKey: "activeProfileId"),
           let id = UUID(uuidString: idString) {
            activeProfileId = id
            // Also restore the active profile's credentials into the fields
            if let profile = savedProfiles.first(where: { $0.id == id }) {
                clientId = profile.clientId
                keyId = profile.keyId
                privateKey = profile.privateKey
            }
        }
    }
    
    
    // Quick reconnect: generates JWT then connects to ABM in one step
    // Includes one automatic retry on network errors (e.g. after switching profiles)
    func reconnect() {
        guard !clientId.isEmpty, !keyId.isEmpty, !privateKey.isEmpty else {
            errorMessage = "Missing credentials. Open Connection Settings to configure."
            return
        }

        isLoading = true
        errorMessage = nil
        statusMessage = nil

        Task {
            var lastError: Error?

            for attempt in 1...2 {
                do {
                    let credentials = APICredentials(
                        clientId: clientId,
                        keyId: keyId,
                        privateKey: privateKey
                    )
                    clientAssertion = try JWTGenerator.createClientAssertion(credentials: credentials)

                    let token = try await apiService.getAccessToken(
                        clientAssertion: clientAssertion!,
                        clientId: clientId
                    )

                    // Only replace data on success
                    let fetchedDevices = try await apiService.fetchDevices(accessToken: token)
                    let fetchedServers = try await apiService.fetchMDMServers(accessToken: token)

                    devices = fetchedDevices
                    mdmServers = fetchedServers

                    statusMessage = "Connected to ABM. Fetched \(devices.count) devices and \(mdmServers.count) servers."
                    lastError = nil
                    break
                } catch let error as NSError where error.domain == NSURLErrorDomain && error.code == -1005 {
                    // Network connection lost — likely a transient HTTP/2 issue
                    lastError = error
                    if attempt == 1 {
                        statusMessage = "Connection interrupted, retrying..."
                        try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                    }
                } catch {
                    lastError = error
                    break // Non-network error, don't retry
                }
            }

            if let error = lastError {
                statusMessage = nil
                errorMessage = "Reconnect Error: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }

    // Get current access token
    func getCurrentAccessToken() async -> String? {
        guard let assertion = clientAssertion else { return nil }

        do {
            return try await apiService.getAccessToken(
                clientAssertion: assertion,
                clientId: clientId
            )
        } catch {
            return nil
        }
    }

    // MARK: - Jamf Pro Connection

    /// Connect to Jamf Pro using OAuth 2.0 Client Credentials
    func connectToJamf() {
        guard !jamfURL.isEmpty, !jamfClientId.isEmpty, !jamfClientSecret.isEmpty else {
            jamfErrorMessage = "Fill in all Jamf Pro connection fields."
            return
        }

        isJamfLoading = true
        jamfErrorMessage = nil
        jamfStatusMessage = nil

        Task {
            do {
                try await jamfAPIService.authenticate(
                    baseURL: jamfURL,
                    clientId: jamfClientId,
                    clientSecret: jamfClientSecret
                )
                isJamfConnected = true
                jamfStatusMessage = "Connected to Jamf Pro"
            } catch {
                isJamfConnected = false
                jamfErrorMessage = error.localizedDescription
            }
            isJamfLoading = false
        }
    }

    /// Get a valid Jamf token, auto-refreshing if needed
    func getJamfToken() async throws -> String {
        try await jamfAPIService.getToken(
            baseURL: jamfURL,
            clientId: jamfClientId,
            clientSecret: jamfClientSecret
        )
    }

    /// Disconnect from Jamf Pro
    func disconnectJamf() {
        jamfAPIService.clearToken()
        isJamfConnected = false
        jamfStatusMessage = nil
        jamfErrorMessage = nil
    }

    // MARK: - Jamf Pro Profiles

    func saveJamfProfile(name: String) {
        let profile = JamfConnectionProfile(
            name: name,
            jamfURL: jamfURL,
            clientId: jamfClientId,
            clientSecret: jamfClientSecret
        )

        if let index = jamfSavedProfiles.firstIndex(where: { $0.name == name }) {
            let oldId = jamfSavedProfiles[index].id
            if oldId != profile.id {
                KeychainHelper.delete(key: "jamf-clientSecret-\(oldId.uuidString)")
            }
            jamfSavedProfiles[index] = profile
        } else {
            jamfSavedProfiles.append(profile)
        }

        KeychainHelper.save(key: "jamf-clientSecret-\(profile.id.uuidString)", value: jamfClientSecret)
        activeJamfProfileId = profile.id
        persistJamfProfiles()
    }

    func switchToJamfProfile(_ profile: JamfConnectionProfile) {
        jamfURL = profile.jamfURL
        jamfClientId = profile.clientId
        jamfClientSecret = profile.clientSecret
        activeJamfProfileId = profile.id

        // Reset connection
        disconnectJamf()
        saveJamfCredentials()
        UserDefaults.standard.set(profile.id.uuidString, forKey: "activeJamfProfileId")
    }

    func deleteJamfProfile(_ profile: JamfConnectionProfile) {
        KeychainHelper.delete(key: "jamf-clientSecret-\(profile.id.uuidString)")
        jamfSavedProfiles.removeAll { $0.id == profile.id }
        if activeJamfProfileId == profile.id {
            activeJamfProfileId = nil
        }
        persistJamfProfiles()
    }

    private func saveJamfCredentials() {
        UserDefaults.standard.set(jamfURL, forKey: "jamfURL")
        UserDefaults.standard.set(jamfClientId, forKey: "jamfClientId")
    }

    private func persistJamfProfiles() {
        if let data = try? JSONEncoder().encode(jamfSavedProfiles) {
            UserDefaults.standard.set(data, forKey: "jamfConnectionProfiles")
        }
        if let id = activeJamfProfileId {
            UserDefaults.standard.set(id.uuidString, forKey: "activeJamfProfileId")
        }
    }

    func loadJamfProfiles() {
        if let data = UserDefaults.standard.data(forKey: "jamfConnectionProfiles"),
           var profiles = try? JSONDecoder().decode([JamfConnectionProfile].self, from: data) {
            // Hydrate secrets from Keychain
            for i in profiles.indices {
                if profiles[i].clientSecret.isEmpty,
                   let secret = KeychainHelper.read(key: "jamf-clientSecret-\(profiles[i].id.uuidString)") {
                    profiles[i].clientSecret = secret
                }
            }
            jamfSavedProfiles = profiles
        }

        if let idString = UserDefaults.standard.string(forKey: "activeJamfProfileId"),
           let id = UUID(uuidString: idString) {
            activeJamfProfileId = id
            if let profile = jamfSavedProfiles.first(where: { $0.id == id }) {
                jamfURL = profile.jamfURL
                jamfClientId = profile.clientId
                jamfClientSecret = profile.clientSecret
            }
        }
    }
}
