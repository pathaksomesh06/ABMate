//
//  ABMViewModel+NewAPIs.swift
//  ABMate
//
//  New Apple Business API endpoints (Users, User Groups, Apps, Packages,
//  Blueprints, Configurations, Audit Events, MDM Enrolled Devices).
//  These are ABM-only unless noted otherwise.
//

import Foundation

// MARK: - Users (ABM only)

extension ABMViewModel {
    func fetchUsers() {
        guard platform.supportsUsers else {
            errorMessage = "Users are only available in \(ApplePlatform.business.displayName)"
            return
        }
        guard let assertion = clientAssertion else { errorMessage = "Generate JWT first"; return }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let token = try await apiService.getAccessToken(clientAssertion: assertion, clientId: clientId, platform: platform)
                users = try await apiService.fetchUsers(accessToken: token, platform: platform)
                statusMessage = "Fetched \(users.count) users"
            } catch { errorMessage = "Error: \(error.localizedDescription)" }
            isLoading = false
        }
    }
}

// MARK: - User Groups (ABM only)

extension ABMViewModel {
    func fetchUserGroups() {
        guard platform.supportsUserGroups else {
            errorMessage = "User Groups are only available in \(ApplePlatform.business.displayName)"
            return
        }
        guard let assertion = clientAssertion else { errorMessage = "Generate JWT first"; return }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let token = try await apiService.getAccessToken(clientAssertion: assertion, clientId: clientId, platform: platform)
                userGroups = try await apiService.fetchUserGroups(accessToken: token, platform: platform)
                statusMessage = "Fetched \(userGroups.count) user groups"
            } catch { errorMessage = "Error: \(error.localizedDescription)" }
            isLoading = false
        }
    }

    func getUserGroupMembers(groupId: String) async -> [String] {
        guard let assertion = clientAssertion else { return [] }
        do {
            let token = try await apiService.getAccessToken(clientAssertion: assertion, clientId: clientId, platform: platform)
            return try await apiService.getUserGroupMembers(groupId: groupId, accessToken: token, platform: platform)
        } catch {
            await MainActor.run { errorMessage = "Error: \(error.localizedDescription)" }
            return []
        }
    }
}

// MARK: - Apps (ABM only)

extension ABMViewModel {
    func fetchApps() {
        guard platform.supportsApps else {
            errorMessage = "Apps are only available in \(ApplePlatform.business.displayName)"
            return
        }
        guard let assertion = clientAssertion else { errorMessage = "Generate JWT first"; return }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let token = try await apiService.getAccessToken(clientAssertion: assertion, clientId: clientId, platform: platform)
                apps = try await apiService.fetchApps(accessToken: token, platform: platform, contentToken: contentToken.isEmpty ? nil : contentToken)
                statusMessage = "Fetched \(apps.count) apps"
            } catch { errorMessage = "Error: \(error.localizedDescription)" }
            isLoading = false
        }
    }
}

// MARK: - Packages (ABM only)

extension ABMViewModel {
    func fetchPackages() {
        guard platform.supportsPackages else {
            errorMessage = "Packages are only available in \(ApplePlatform.business.displayName)"
            return
        }
        guard let assertion = clientAssertion else { errorMessage = "Generate JWT first"; return }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let token = try await apiService.getAccessToken(clientAssertion: assertion, clientId: clientId, platform: platform)
                packages = try await apiService.fetchPackages(accessToken: token, platform: platform)
                statusMessage = "Fetched \(packages.count) packages"
            } catch { errorMessage = "Error: \(error.localizedDescription)" }
            isLoading = false
        }
    }
}

// MARK: - Blueprints (ABM only)

extension ABMViewModel {
    func fetchBlueprints() {
        guard platform.supportsBlueprints else {
            errorMessage = "Blueprints are only available in \(ApplePlatform.business.displayName)"
            return
        }
        guard let assertion = clientAssertion else { errorMessage = "Generate JWT first"; return }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let token = try await apiService.getAccessToken(clientAssertion: assertion, clientId: clientId, platform: platform)
                blueprints = try await apiService.fetchBlueprints(accessToken: token, platform: platform)
                statusMessage = "Fetched \(blueprints.count) blueprints"
            } catch { errorMessage = "Error: \(error.localizedDescription)" }
            isLoading = false
        }
    }
}

// MARK: - Configurations (ABM only)

extension ABMViewModel {
    func fetchConfigurations() {
        guard platform.supportsConfigurations else {
            errorMessage = "Configurations are only available in \(ApplePlatform.business.displayName)"
            return
        }
        guard let assertion = clientAssertion else { errorMessage = "Generate JWT first"; return }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let token = try await apiService.getAccessToken(clientAssertion: assertion, clientId: clientId, platform: platform)
                configurations = try await apiService.fetchConfigurations(accessToken: token, platform: platform)
                statusMessage = "Fetched \(configurations.count) configurations"
            } catch { errorMessage = "Error: \(error.localizedDescription)" }
            isLoading = false
        }
    }
}

// MARK: - Audit Events (ABM only)

extension ABMViewModel {
    func fetchAuditEvents(startDateTime: String? = nil, endDateTime: String? = nil) {
        guard platform.supportsAuditEvents else {
            errorMessage = "Audit Events are only available in \(ApplePlatform.business.displayName)"
            return
        }
        guard let assertion = clientAssertion else { errorMessage = "Generate JWT first"; return }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let token = try await apiService.getAccessToken(clientAssertion: assertion, clientId: clientId, platform: platform)
                auditEvents = try await apiService.fetchAuditEvents(accessToken: token, platform: platform, startDateTime: startDateTime, endDateTime: endDateTime)
                statusMessage = "Fetched \(auditEvents.count) audit events"
            } catch { errorMessage = "Error: \(error.localizedDescription)" }
            isLoading = false
        }
    }
}

// MARK: - MDM Enrolled Devices (ABM only)

extension ABMViewModel {
    func fetchMdmEnrolledDevices() {
        guard platform.supportsMdmEnrolledDevices else {
            errorMessage = "MDM Enrolled Devices are only available in \(ApplePlatform.business.displayName)"
            return
        }
        guard let assertion = clientAssertion else { errorMessage = "Generate JWT first"; return }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let token = try await apiService.getAccessToken(clientAssertion: assertion, clientId: clientId, platform: platform)
                mdmEnrolledDevices = try await apiService.fetchMdmEnrolledDevices(accessToken: token, platform: platform)
                statusMessage = "Fetched \(mdmEnrolledDevices.count) MDM enrolled devices"
            } catch { errorMessage = "Error: \(error.localizedDescription)" }
            isLoading = false
        }
    }
}
