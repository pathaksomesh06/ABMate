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
    
    // Connect to ABM
    func connectToABM() {
        guard let assertion = clientAssertion else {
            errorMessage = "Generate JWT first"
            return
        }

        isLoading = true
        errorMessage = nil
        statusMessage = nil
        devices = []
        mdmServers = []

        Task {
            do {
                let token = try await apiService.getAccessToken(
                    clientAssertion: assertion,
                    clientId: clientId
                )
                
                print("Successfully obtained access token. Fetching data...")
                
                // Fetch devices and servers
                let fetchedDevices = try await apiService.fetchDevices(accessToken: token)
                print("Successfully fetched \(fetchedDevices.count) devices.")
                devices = fetchedDevices
                
                let fetchedServers = try await apiService.fetchMDMServers(accessToken: token)
                print("Successfully fetched \(fetchedServers.count) servers.")
                mdmServers = fetchedServers
                
                statusMessage = "Connected to ABM. Fetched \(devices.count) devices and \(mdmServers.count) servers."
            } catch {
                print("Error during ABM connection: \(error)")
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
}
