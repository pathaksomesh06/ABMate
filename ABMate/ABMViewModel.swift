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
    @Published var warningMessage: String?
    @Published var statusMessage: String?
    @Published var lastActivityId: String?
    @Published var fetchProgress: Int = 0
    
    // ABM-only data
    @Published var users: [ABMUser] = []
    @Published var userGroups: [ABMUserGroup] = []
    @Published var apps: [ABMApp] = []
    @Published var packages: [ABMPackage] = []
    @Published var blueprints: [Blueprint] = []
    @Published var configurations: [ABMConfiguration] = []
    @Published var auditEvents: [AuditEvent] = []
    @Published var mdmEnrolledDevices: [MdmEnrolledDevice] = []
    
    // Credentials
    @Published var clientId = ""
    @Published var keyId = ""
    @Published var privateKey = ""
    @Published var contentToken = ""  // VPP / Apps & Books content token (downloaded from ABM Settings)
    @Published var platform: ApplePlatform = .business {
        didSet {
            handlePlatformChange(from: oldValue)
        }
    }
    
    internal let apiService = APIService()
    internal var clientAssertion: String?
    private let platformKey = "platform"
    
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
        fetchProgress = 0
        
        Task {
            do {
                let token = try await apiService.getAccessToken(
                    clientAssertion: assertion,
                    clientId: clientId,
                    platform: platform
                )
                
                let result = try await apiService.fetchDevices(accessToken: token, platform: platform) { [weak self] count in
                    Task { @MainActor in
                        self?.fetchProgress = count
                        self?.statusMessage = "Fetching devices… (\(count.formatted()) so far)"
                    }
                }
                devices = result.devices
                if result.isTruncated {
                    warningMessage = "Partial fetch: \(result.devices.count.formatted()) devices loaded from \(result.pagesCompleted) pages. Some data may be missing."
                    statusMessage = "Fetched \(devices.count.formatted()) devices (incomplete)"
                } else {
                    statusMessage = "Fetched \(devices.count.formatted()) devices"
                }
            } catch {
                errorMessage = "API Error: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
    
    // Connect to Apple Business/School Manager
    func connectToABM() {
        guard let assertion = clientAssertion else {
            errorMessage = "Generate JWT first"
            return
        }

        isLoading = true
        errorMessage = nil
        warningMessage = nil
        statusMessage = nil
        fetchProgress = 0
        devices = []
        mdmServers = []

        Task {
            do {
                let token = try await apiService.getAccessToken(
                    clientAssertion: assertion,
                    clientId: clientId,
                    platform: platform
                )
                
                print("Successfully obtained access token. Fetching data...")
                
                // Fetch devices with progress reporting
                let result = try await apiService.fetchDevices(accessToken: token, platform: platform) { [weak self] count in
                    Task { @MainActor in
                        self?.fetchProgress = count
                        self?.statusMessage = "Fetching devices… (\(count.formatted()) so far)"
                    }
                }
                print("Successfully fetched \(result.devices.count) devices (truncated: \(result.isTruncated)).")
                devices = result.devices
                
                if result.isTruncated {
                    warningMessage = "Partial fetch: \(result.devices.count.formatted()) of total devices loaded. Some data may be missing."
                }
                
                let fetchedServers = try await apiService.fetchMDMServers(accessToken: token, platform: platform)
                print("Successfully fetched \(fetchedServers.count) servers.")
                mdmServers = fetchedServers
                
                // Fetch ABM-only data in parallel when on Business platform.
                // Each endpoint is fetched independently so a 403 on one
                // does not block the others (API key may lack some scopes).
                var abmWarnings: [String] = []
                if platform == .business {
                    async let fetchedUsers = apiService.fetchUsers(accessToken: token, platform: platform)
                    async let fetchedGroups = apiService.fetchUserGroups(accessToken: token, platform: platform)
                    async let fetchedApps = apiService.fetchApps(accessToken: token, platform: platform, contentToken: contentToken.isEmpty ? nil : contentToken)
                    async let fetchedPackages = apiService.fetchPackages(accessToken: token, platform: platform)
                    async let fetchedBlueprints = apiService.fetchBlueprints(accessToken: token, platform: platform)
                    async let fetchedConfigs = apiService.fetchConfigurations(accessToken: token, platform: platform)
                    
                    do { users = try await fetchedUsers }
                    catch { abmWarnings.append("Users"); print("Users fetch failed: \(error.localizedDescription)") }
                    do { userGroups = try await fetchedGroups }
                    catch { abmWarnings.append("User Groups"); print("User Groups fetch failed: \(error.localizedDescription)") }
                    do { apps = try await fetchedApps }
                    catch { abmWarnings.append("Apps"); print("Apps fetch failed: \(error.localizedDescription)") }
                    do { packages = try await fetchedPackages }
                    catch { abmWarnings.append("Packages"); print("Packages fetch failed: \(error.localizedDescription)") }
                    do { blueprints = try await fetchedBlueprints }
                    catch { abmWarnings.append("Blueprints"); print("Blueprints fetch failed: \(error.localizedDescription)") }
                    do { configurations = try await fetchedConfigs }
                    catch { abmWarnings.append("Configurations"); print("Configurations fetch failed: \(error.localizedDescription)") }
                    
                    print("ABM data: \(users.count) users, \(userGroups.count) groups, \(apps.count) apps, \(packages.count) packages, \(blueprints.count) blueprints, \(configurations.count) configurations")
                }
                
                statusMessage = "Connected to \(platform.displayName). Fetched \(devices.count.formatted()) devices and \(mdmServers.count) servers."
                if !abmWarnings.isEmpty {
                    warningMessage = (warningMessage ?? "") + "API key lacks permission for: \(abmWarnings.joined(separator: ", ")). Check your key's scopes in Apple Business Manager."
                }
            } catch {
                print("Error during \(platform.shortName) connection: \(error)")
                errorMessage = "\(platform.shortName) Connection Error: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }

    private func handlePlatformChange(from oldValue: ApplePlatform) {
        guard oldValue != platform else { return }
        apiService.resetToken()
        clientAssertion = nil
        devices = []
        mdmServers = []
        activityStatus = nil
        lastActivityId = nil
        // Clear ABM-only data
        users = []
        userGroups = []
        apps = []
        packages = []
        blueprints = []
        configurations = []
        auditEvents = []
        mdmEnrolledDevices = []
        statusMessage = "Switched to \(platform.displayName). Generate a new JWT to connect."
        errorMessage = nil
        warningMessage = nil
        savePlatform()
    }

    // Save credentials to UserDefaults
    private func saveCredentials() {
        UserDefaults.standard.set(clientId, forKey: "clientId")
        UserDefaults.standard.set(keyId, forKey: "keyId")
        UserDefaults.standard.set(contentToken, forKey: "contentToken")
        savePlatform()
    }

    private func savePlatform() {
        UserDefaults.standard.set(platform.rawValue, forKey: platformKey)
    }
    
    // Load saved credentials
    func loadCredentials() {
        clientId = UserDefaults.standard.string(forKey: "clientId") ?? ""
        keyId = UserDefaults.standard.string(forKey: "keyId") ?? ""
        contentToken = UserDefaults.standard.string(forKey: "contentToken") ?? ""
        if let savedPlatform = UserDefaults.standard.string(forKey: platformKey),
           let platformValue = ApplePlatform(rawValue: savedPlatform) {
            platform = platformValue
        }
    }
    
    
    // Get current access token
    func getCurrentAccessToken() async -> String? {
        guard let assertion = clientAssertion else { return nil }
        
        do {
            return try await apiService.getAccessToken(
                clientAssertion: assertion,
                clientId: clientId,
                platform: platform
            )
        } catch {
            return nil
        }
    }
}
