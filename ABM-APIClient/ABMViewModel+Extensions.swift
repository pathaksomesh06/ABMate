//
//  ABMViewModel+Extensions.swift
//  ABM-APIClient
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
                    clientId: clientId
                )
                mdmServers = try await apiService.fetchMDMServers(accessToken: token)
                statusMessage = "Fetched \(mdmServers.count) MDM servers"
            } catch {
                errorMessage = "Error: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
    
    // Get device assigned server
    func getDeviceAssignedServer(deviceId: String) async {
        guard let assertion = clientAssertion else { return }
        
        do {
            let token = try await apiService.getAccessToken(
                clientAssertion: assertion,
                clientId: clientId
            )
            
            statusMessage = "Server info fetched"
        } catch {
            errorMessage = "Error: \(error.localizedDescription)"
        }
    }
    
    // Get devices for MDM
    func getDevicesForMDM(mdmId: String) async {
        guard let assertion = clientAssertion else { return }
        
        do {
            let token = try await apiService.getAccessToken(
                clientAssertion: assertion,
                clientId: clientId
            )
            let deviceIds = try await apiService.getDevicesForMDM(mdmId: mdmId, accessToken: token)
            statusMessage = "MDM has \(deviceIds.count) devices"
        } catch {
            errorMessage = "Error: \(error.localizedDescription)"
        }
    }
    
    // Assign devices
    func assignDevices(deviceIds: [String], mdmId: String?) async {
        guard let assertion = clientAssertion else { return }
        
        do {
            let token = try await apiService.getAccessToken(
                clientAssertion: assertion,
                clientId: clientId
            )
            let activityId = try await apiService.assignDevices(
                deviceIds: deviceIds,
                mdmId: mdmId,
                accessToken: token
            )
            statusMessage = "Activity started: \(activityId)"
            lastActivityId = activityId
        } catch {
            errorMessage = "Error: \(error.localizedDescription)"
        }
    }
    
    // Check activity status
    func checkActivityStatus(activityId: String) async {
        guard let assertion = clientAssertion else { return }
        
        do {
            let token = try await apiService.getAccessToken(
                clientAssertion: assertion,
                clientId: clientId
            )
            activityStatus = try await apiService.checkActivityStatus(
                activityId: activityId,
                accessToken: token
            )
            statusMessage = "Status: \(activityStatus?.data.attributes.status ?? "Unknown")"
        } catch {
            errorMessage = "Error: \(error.localizedDescription)"
        }
    }
}
