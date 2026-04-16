//
//  ABMViewModel+Extensions.swift
//  ABMate
//
//  © Created by Somesh Pathak on 23/06/2025.
//

import Foundation

extension ABMViewModel {
    // Fetch MDM servers
    func fetchMDMServers() {
        guard let assertion = clientAssertion else {
            errorMessage = "Generate JWT first"
            return
        }
        
        isLoading = true
        Task {
            do {
                let token = try await apiService.getAccessToken(
                    clientAssertion: assertion,
                    clientId: clientId,
                    platform: platform
                )
                mdmServers = try await apiService.fetchMDMServers(accessToken: token, platform: platform)
                statusMessage = "Fetched \(mdmServers.count) MDM servers"
            } catch {
                errorMessage = "Error: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
    
    // Get device assigned server
    func getDeviceAssignedServer(deviceId: String) async -> String? {
        guard let assertion = clientAssertion else { return nil }
        
        do {
            let token = try await apiService.getAccessToken(
                clientAssertion: assertion,
                clientId: clientId,
                platform: platform
            )
            
            if let serverId = try await apiService.getAssignedServer(deviceId: deviceId, accessToken: token, platform: platform) {
                // Find server name from mdmServers
                if let server = mdmServers.first(where: { $0.id == serverId }) {
                    return server.attributes.serverName
                }
                return serverId
            }
            return nil
        } catch {
            errorMessage = "Error: \(error.localizedDescription)"
            return nil
        }
    }
    
    // Get AppleCare Coverage for a device
    func getAppleCareCoverage(deviceId: String) async -> AppleCareCoverage? {
        guard let assertion = clientAssertion else {
            await MainActor.run { errorMessage = "Connect to \(platform.displayName) first" }
            return nil
        }
        
        do {
            let token = try await apiService.getAccessToken(
                clientAssertion: assertion,
                clientId: clientId,
                platform: platform
            )
            
            let coverage = try await apiService.getAppleCareCoverage(deviceId: deviceId, accessToken: token, platform: platform)
            print("ViewModel: AppleCare coverage retrieved successfully")
            return coverage
        } catch {
            print("ViewModel: AppleCare error - \(error.localizedDescription)")
            await MainActor.run { errorMessage = error.localizedDescription }
            return nil
        }
    }
    
    // Get devices for MDM
    func getDevicesForMDM(mdmId: String) async {
        guard let assertion = clientAssertion else { return }
        
        do {
            let token = try await apiService.getAccessToken(
                clientAssertion: assertion,
                clientId: clientId,
                platform: platform
            )
            let deviceIds = try await apiService.getDevicesForMDM(mdmId: mdmId, accessToken: token, platform: platform)
            statusMessage = "MDM has \(deviceIds.count) devices"
        } catch {
            errorMessage = "Error: \(error.localizedDescription)"
        }
    }
    
    // Assign devices
    func assignDevices(deviceIds: [String], mdmId: String?) async {
        guard let assertion = clientAssertion else {
            await MainActor.run {
                errorMessage = "Connect to \(platform.displayName) first"
            }
            return
        }
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            statusMessage = nil
        }
        
        do {
            let token = try await apiService.getAccessToken(
                clientAssertion: assertion,
                clientId: clientId,
                platform: platform
            )
            let activityId = try await apiService.assignDevices(
                deviceIds: deviceIds,
                mdmId: mdmId,
                accessToken: token,
                platform: platform
            )
            
            let action = mdmId != nil ? "assigned" : "unassigned"
            let deviceCount = deviceIds.count
            await MainActor.run {
                statusMessage = "Successfully \(action) \(deviceCount) device\(deviceCount == 1 ? "" : "s"). Activity ID: \(activityId)"
                lastActivityId = activityId
            }
        } catch {
            await MainActor.run {
                errorMessage = "Assignment failed: \(error.localizedDescription)"
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    // Check activity status
    func checkActivityStatus(activityId: String) async {
        guard let assertion = clientAssertion else {
            await MainActor.run {
                errorMessage = "Connect to \(platform.displayName) first"
            }
            return
        }
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            statusMessage = nil
        }
        
        do {
            let token = try await apiService.getAccessToken(
                clientAssertion: assertion,
                clientId: clientId,
                platform: platform
            )
            let status = try await apiService.checkActivityStatus(
                activityId: activityId,
                accessToken: token,
                platform: platform
            )
            
            await MainActor.run {
                activityStatus = status
                let statusText = status.data.attributes.status
                let subStatus = status.data.attributes.subStatus
                statusMessage = "Activity Status: \(statusText)\(subStatus.isEmpty ? "" : " (\(subStatus))")"
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to check activity: \(error.localizedDescription)"
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
}
