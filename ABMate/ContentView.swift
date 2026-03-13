//
//  ContentView.swift
//  ABMate
//
//  © Created by Somesh Pathak on 23/06/2025.
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Navigation
enum NavigationItem: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case devices = "Devices"
    case mdmServers = "MDM Servers"
    case assign = "Assign"
    case activity = "Activity"
    case mdmSync = "MDM Sync"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2"
        case .devices: return "laptopcomputer.and.iphone"
        case .mdmServers: return "server.rack"
        case .assign: return "arrow.triangle.swap"
        case .activity: return "clock.arrow.circlepath"
        case .mdmSync: return "arrow.triangle.2.circlepath"
        }
    }
}

// MARK: - Main Content View
struct ContentView: View {
    @StateObject private var viewModel = ABMViewModel()
    @State private var selectedNavItem: NavigationItem = .dashboard
    @State private var showingSettings = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .doubleColumn
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar
            VStack(spacing: 0) {
                // App Header
                HStack(spacing: 10) {
                    Image(systemName: "apple.terminal")
                        .font(.title2)
                        .foregroundStyle(.blue.gradient)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ABMate")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                        Text("v1.0")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                // Active Profile Indicator with connection state
                if let profileName = viewModel.activeProfileName {
                    VStack(spacing: 6) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(viewModel.isConnected ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(profileName)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                Text(viewModel.isConnected ? "Connected" : "Not Connected")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(viewModel.isConnected ? .green : .red)
                            }
                            Spacer()
                        }

                        if !viewModel.isConnected {
                            Button(action: { viewModel.reconnect() }) {
                                HStack(spacing: 4) {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .scaleEffect(0.5)
                                            .frame(width: 12, height: 12)
                                    } else {
                                        Image(systemName: "bolt.fill")
                                            .font(.system(size: 10))
                                    }
                                    Text("Connect")
                                        .font(.system(size: 11, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 5)
                                .background(Color.accentColor.opacity(0.12))
                                .foregroundColor(.accentColor)
                                .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                            .disabled(viewModel.isLoading)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(viewModel.isConnected ? Color.green.opacity(0.06) : Color.red.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(viewModel.isConnected ? Color.green.opacity(0.2) : Color.red.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 12)
                    .padding(.bottom, 4)
                    .contextMenu {
                        Button(action: { showingSettings = true }) {
                            Label("Connection Settings", systemImage: "gearshape")
                        }
                        if viewModel.isConnected {
                            Button(action: { viewModel.reconnect() }) {
                                Label("Reconnect", systemImage: "arrow.clockwise")
                            }
                        } else {
                            Button(action: { viewModel.reconnect() }) {
                                Label("Connect", systemImage: "bolt.fill")
                            }
                        }
                    }
                }

                Divider()
                    .padding(.horizontal, 12)

                // Navigation List
                List(NavigationItem.allCases, selection: $selectedNavItem) { item in
                    NavigationLink(value: item) {
                        Label(item.rawValue, systemImage: item.icon)
                    }
                }
                .listStyle(.sidebar)
                
                Divider()
                    .padding(.horizontal, 12)

                // Settings Button
                Button(action: { showingSettings = true }) {
                    HStack {
                        Image(systemName: "gearshape")
                        Text("Connection")
                        Spacer()
                        if viewModel.isLoading {
                            ProgressView()
                                .scaleEffect(0.6)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundColor(.primary)
            }
            .navigationSplitViewColumnWidth(min: 220, ideal: 220, max: 220)
        } detail: {
            // Main Content
            Group {
                switch selectedNavItem {
                case .dashboard:
                    DashboardView(viewModel: viewModel, onOpenSettings: { showingSettings = true }, onNavigateToActivity: { selectedNavItem = .activity })
                case .devices:
                    DevicesView(viewModel: viewModel)
                case .mdmServers:
                    MDMServersView(viewModel: viewModel)
                case .assign:
                    DeviceAssignmentView(viewModel: viewModel)
                case .activity:
                    ActivityStatusView(viewModel: viewModel)
                case .mdmSync:
                    JamfSyncView(viewModel: viewModel)
                }
            }
            .frame(minWidth: 600)
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minHeight: 650)
        .onAppear {
            viewModel.loadCredentials()
        }
        .sheet(isPresented: $showingSettings) {
            ConnectionSettingsSheet(viewModel: viewModel)
        }
    }
}

// MARK: - Connection Badge
struct ConnectionBadge: View {
    let isConnected: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isConnected ? Color.green : Color.orange)
                .frame(width: 6, height: 6)
            Text(isConnected ? "Connected" : "Offline")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(isConnected ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
        )
    }
}

// MARK: - Connection Settings Sheet
struct ConnectionSettingsSheet: View {
    @ObservedObject var viewModel: ABMViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingKeyImporter = false
    @State private var profileName = ""
    @State private var showingSaveProfile = false
    @State private var isCreatingNewProfile = false
    @State private var showingDeleteConfirm = false
    @State private var profileToDelete: ConnectionProfile?
    // Snapshot of credentials before "New Profile" clears them
    @State private var previousClientId = ""
    @State private var previousKeyId = ""
    @State private var previousPrivateKey = ""
    @State private var previousProfileId: UUID?
    @State private var previousAssertion: String?

    // Jamf Pro profile management
    @State private var jamfProfileName = ""
    @State private var showingSaveJamfProfile = false
    @State private var showingJamfDeleteConfirm = false
    @State private var jamfProfileToDelete: JamfConnectionProfile?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Connection Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(20)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Connection Profiles Section
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Connection Profiles", systemImage: "person.2.badge.gearshape")
                            .font(.headline)

                        if viewModel.savedProfiles.isEmpty {
                            Text("No saved profiles. Fill in credentials and save a profile to get started.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            VStack(spacing: 8) {
                                ForEach(viewModel.savedProfiles) { profile in
                                    HStack(spacing: 12) {
                                        Image(systemName: profile.id == viewModel.activeProfileId ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(profile.id == viewModel.activeProfileId ? .green : .secondary)
                                            .font(.title3)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(profile.name)
                                                .font(.system(.body, weight: .medium))
                                            Text(profile.clientId.prefix(30) + (profile.clientId.count > 30 ? "..." : ""))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }

                                        Spacer()

                                        if profile.id != viewModel.activeProfileId {
                                            Button("Switch") {
                                                viewModel.switchToProfile(profile)
                                            }
                                            .buttonStyle(.bordered)
                                            .controlSize(.small)
                                        } else {
                                            Text("Active")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.green)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(
                                                    Capsule().fill(Color.green.opacity(0.1))
                                                )
                                        }

                                        Button(action: {
                                            profileToDelete = profile
                                            showingDeleteConfirm = true
                                        }) {
                                            Image(systemName: "trash")
                                                .foregroundColor(.red.opacity(0.7))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(profile.id == viewModel.activeProfileId ? Color.green.opacity(0.05) : Color(NSColor.controlBackgroundColor))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(profile.id == viewModel.activeProfileId ? Color.green.opacity(0.3) : Color.clear, lineWidth: 1)
                                    )
                                }
                            }
                        }

                        // Profile Actions
                        if showingSaveProfile {
                            HStack(spacing: 8) {
                                TextField("Profile name...", text: $profileName)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(maxWidth: 200)

                                Button("Save") {
                                    if !profileName.isEmpty {
                                        viewModel.saveProfile(name: profileName)
                                        profileName = ""
                                        showingSaveProfile = false
                                        isCreatingNewProfile = false
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                                .disabled(profileName.isEmpty)

                                Button("Cancel") {
                                    // Restore previous credentials if we were creating a new profile
                                    if isCreatingNewProfile {
                                        viewModel.clientId = previousClientId
                                        viewModel.keyId = previousKeyId
                                        viewModel.privateKey = previousPrivateKey
                                        viewModel.activeProfileId = previousProfileId
                                        viewModel.clientAssertion = previousAssertion
                                    }
                                    showingSaveProfile = false
                                    isCreatingNewProfile = false
                                    profileName = ""
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        } else {
                            HStack(spacing: 8) {
                                Button(action: {
                                    // Snapshot current credentials before clearing
                                    previousClientId = viewModel.clientId
                                    previousKeyId = viewModel.keyId
                                    previousPrivateKey = viewModel.privateKey
                                    previousProfileId = viewModel.activeProfileId
                                    previousAssertion = viewModel.clientAssertion

                                    // Clear credentials for a fresh profile
                                    viewModel.clientId = ""
                                    viewModel.keyId = ""
                                    viewModel.privateKey = ""
                                    viewModel.activeProfileId = nil
                                    viewModel.clientAssertion = nil
                                    viewModel.statusMessage = nil
                                    viewModel.errorMessage = nil
                                    isCreatingNewProfile = true
                                    showingSaveProfile = true
                                }) {
                                    Label("New Profile", systemImage: "plus.circle")
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)

                                Button(action: { showingSaveProfile = true }) {
                                    Label("Save Current", systemImage: "square.and.arrow.down")
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .disabled(viewModel.clientId.isEmpty || viewModel.keyId.isEmpty || viewModel.privateKey.isEmpty)
                            }
                        }
                    }

                    Divider()

                    // Credentials Section
                    VStack(alignment: .leading, spacing: 16) {
                        Label("API Credentials", systemImage: "key.fill")
                            .font(.headline)
                        
                        VStack(spacing: 12) {
                            CredentialField(
                                label: "Client ID",
                                placeholder: "BUSINESSAPI. or SCHOOLAPI.xxxxxxxx-xxxx-...",
                                text: $viewModel.clientId,
                                icon: "person.badge.key"
                            )
                            
                            CredentialField(
                                label: "Key ID",
                                placeholder: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
                                text: $viewModel.keyId,
                                icon: "key.horizontal"
                            )
                            
                            // Private Key
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Private Key")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Button(action: { showingKeyImporter = true }) {
                                    HStack {
                                        Image(systemName: viewModel.privateKey.isEmpty ? "doc.badge.plus" : "checkmark.seal.fill")
                                            .foregroundColor(viewModel.privateKey.isEmpty ? .blue : .green)
                                        Text(viewModel.privateKey.isEmpty ? "Import .p8 Private Key" : "Private Key Loaded")
                                            .foregroundColor(.primary)
                                        Spacer()
                                        if !viewModel.privateKey.isEmpty {
                                            Button(action: { viewModel.privateKey = "" }) {
                                                Image(systemName: "trash")
                                                    .foregroundColor(.red.opacity(0.8))
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(NSColor.controlBackgroundColor))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(viewModel.privateKey.isEmpty ? Color.blue.opacity(0.3) : Color.green.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Actions
                    VStack(spacing: 12) {
                        Button(action: { viewModel.generateJWT() }) {
                            HStack {
                                Image(systemName: "lock.rotation")
                                Text("Generate JWT Token")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(!canGenerateJWT)
                        
                        Button(action: {
                            viewModel.connectToABM()
                        }) {
                            HStack {
                                Image(systemName: "bolt.fill")
                                Text("Connect to ABM")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .disabled(viewModel.clientAssertion == nil || viewModel.isLoading)
                    }
                    
                    // Status Messages
                    if viewModel.isLoading || viewModel.statusMessage != nil || viewModel.errorMessage != nil {
                        StatusMessageView(
                            isLoading: viewModel.isLoading,
                            statusMessage: viewModel.statusMessage,
                            errorMessage: viewModel.errorMessage
                        )
                    }

                    Divider()
                        .padding(.vertical, 4)

                    // MARK: Jamf Pro Connection
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Jamf Pro Connection", systemImage: "server.rack")
                            .font(.headline)

                        // Jamf Saved Profiles
                        if !viewModel.jamfSavedProfiles.isEmpty {
                            VStack(spacing: 8) {
                                ForEach(viewModel.jamfSavedProfiles) { profile in
                                    HStack(spacing: 12) {
                                        Image(systemName: profile.id == viewModel.activeJamfProfileId ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(profile.id == viewModel.activeJamfProfileId ? .green : .secondary)
                                            .font(.title3)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(profile.name)
                                                .font(.system(.body, weight: .medium))
                                            Text(profile.jamfURL.prefix(40) + (profile.jamfURL.count > 40 ? "..." : ""))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }

                                        Spacer()

                                        if profile.id != viewModel.activeJamfProfileId {
                                            Button("Switch") {
                                                viewModel.switchToJamfProfile(profile)
                                            }
                                            .buttonStyle(.bordered)
                                            .controlSize(.small)
                                        } else {
                                            Text(viewModel.isJamfConnected ? "Connected" : "Active")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundColor(viewModel.isJamfConnected ? .green : .blue)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(
                                                    Capsule().fill(viewModel.isJamfConnected ? Color.green.opacity(0.1) : Color.blue.opacity(0.1))
                                                )
                                        }

                                        Button(action: {
                                            jamfProfileToDelete = profile
                                            showingJamfDeleteConfirm = true
                                        }) {
                                            Image(systemName: "trash")
                                                .foregroundColor(.red.opacity(0.7))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(profile.id == viewModel.activeJamfProfileId ? Color.green.opacity(0.05) : Color(NSColor.controlBackgroundColor))
                                    )
                                }
                            }
                        }

                        // Jamf Profile Save
                        if showingSaveJamfProfile {
                            HStack(spacing: 8) {
                                TextField("Jamf profile name...", text: $jamfProfileName)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(maxWidth: 200)

                                Button("Save") {
                                    if !jamfProfileName.isEmpty {
                                        viewModel.saveJamfProfile(name: jamfProfileName)
                                        jamfProfileName = ""
                                        showingSaveJamfProfile = false
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                                .disabled(jamfProfileName.isEmpty)

                                Button("Cancel") {
                                    showingSaveJamfProfile = false
                                    jamfProfileName = ""
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        } else {
                            HStack(spacing: 8) {
                                Button(action: { showingSaveJamfProfile = true }) {
                                    Label("Save Current", systemImage: "square.and.arrow.down")
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .disabled(viewModel.jamfURL.isEmpty || viewModel.jamfClientId.isEmpty || viewModel.jamfClientSecret.isEmpty)
                            }
                        }

                        // Setup Instructions
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                Text("Jamf Pro Setup")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("In Jamf Pro, go to **Settings > System > API Roles and Clients**.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("1. Create an **API Role** with these privileges:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                VStack(alignment: .leading, spacing: 2) {
                                    Label("Read Computers", systemImage: "checkmark.circle.fill")
                                    Label("Update Computers", systemImage: "checkmark.circle.fill")
                                    Label("Read Mobile Devices", systemImage: "checkmark.circle.fill")
                                    Label("Update Mobile Devices", systemImage: "checkmark.circle.fill")
                                }
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(.green)
                                .padding(.leading, 12)
                                .padding(.vertical, 4)

                                Text("2. Create an **API Client**, assign the role above, and enable it.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("3. Copy the **Client ID** and generate a **Client Secret** below.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.blue.opacity(0.05))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.blue.opacity(0.15), lineWidth: 1))
                        )

                        // Jamf Credentials
                        VStack(spacing: 12) {
                            CredentialField(
                                label: "Jamf Pro URL",
                                placeholder: "https://yourorg.jamfcloud.com",
                                text: $viewModel.jamfURL,
                                icon: "globe"
                            )

                            CredentialField(
                                label: "Client ID",
                                placeholder: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
                                text: $viewModel.jamfClientId,
                                icon: "person.badge.key"
                            )

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Client Secret")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                HStack(spacing: 10) {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(.secondary)
                                        .frame(width: 20)
                                    SecureField("Client secret...", text: $viewModel.jamfClientSecret)
                                        .textFieldStyle(.plain)
                                }
                                .padding(10)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(NSColor.controlBackgroundColor))
                                )
                            }
                        }

                        // Jamf Connect Button
                        Button(action: { viewModel.connectToJamf() }) {
                            HStack {
                                if viewModel.isJamfLoading {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                } else {
                                    Image(systemName: "bolt.fill")
                                }
                                Text(viewModel.isJamfConnected ? "Reconnect to Jamf Pro" : "Connect to Jamf Pro")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                        .controlSize(.large)
                        .disabled(viewModel.jamfURL.isEmpty || viewModel.jamfClientId.isEmpty || viewModel.jamfClientSecret.isEmpty || viewModel.isJamfLoading)

                        // Jamf Status
                        if viewModel.isJamfLoading || viewModel.jamfStatusMessage != nil || viewModel.jamfErrorMessage != nil {
                            StatusMessageView(
                                isLoading: viewModel.isJamfLoading,
                                statusMessage: viewModel.jamfStatusMessage,
                                errorMessage: viewModel.jamfErrorMessage
                            )
                        }
                    }
                }
                .padding(20)
            }
        }
        .frame(width: 480, height: 780)
        .alert("Delete ABM Profile", isPresented: $showingDeleteConfirm) {
            Button("Cancel", role: .cancel) { profileToDelete = nil }
            Button("Delete", role: .destructive) {
                if let profile = profileToDelete {
                    viewModel.deleteProfile(profile)
                    profileToDelete = nil
                }
            }
        } message: {
            Text("Are you sure you want to delete \"\(profileToDelete?.name ?? "")\"? This cannot be undone.")
        }
        .alert("Delete Jamf Profile", isPresented: $showingJamfDeleteConfirm) {
            Button("Cancel", role: .cancel) { jamfProfileToDelete = nil }
            Button("Delete", role: .destructive) {
                if let profile = jamfProfileToDelete {
                    viewModel.deleteJamfProfile(profile)
                    jamfProfileToDelete = nil
                }
            }
        } message: {
            Text("Are you sure you want to delete \"\(jamfProfileToDelete?.name ?? "")\"? This cannot be undone.")
        }
        .fileImporter(
            isPresented: $showingKeyImporter,
            allowedContentTypes: [.plainText, .item],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let files):
                if let file = files.first {
                    loadPrivateKey(from: file)
                }
            case .failure(let error):
                viewModel.errorMessage = "Failed to load key: \(error.localizedDescription)"
            }
        }
        .onChange(of: viewModel.statusMessage) { oldValue, newValue in
            // Auto-close when successfully connected
            if let message = newValue, message.contains("Connected to ABM") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    dismiss()
                }
            }
        }
    }
    
    private var canGenerateJWT: Bool {
        !viewModel.clientId.isEmpty && !viewModel.keyId.isEmpty && !viewModel.privateKey.isEmpty
    }
    
    private func loadPrivateKey(from url: URL) {
        if url.startAccessingSecurityScopedResource() {
            defer { url.stopAccessingSecurityScopedResource() }
            do {
                viewModel.privateKey = try String(contentsOf: url, encoding: .utf8)
            } catch {
                viewModel.errorMessage = "Failed to read key: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Credential Field
struct CredentialField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                TextField(placeholder, text: $text)
                    .textFieldStyle(.plain)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(NSColor.controlBackgroundColor))
            )
        }
    }
}

// MARK: - Status Message View
struct StatusMessageView: View {
    let isLoading: Bool
    let statusMessage: String?
    let errorMessage: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Connecting...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            if let status = statusMessage {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(status)
                        .font(.subheadline)
                }
            }
            
            if let error = errorMessage {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.1))
        )
    }
}

// MARK: - Dashboard View
struct DashboardView: View {
    @ObservedObject var viewModel: ABMViewModel
    let onOpenSettings: () -> Void
    let onNavigateToActivity: () -> Void
    @State private var showingExporter = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Dashboard")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                        Text("Overview of your Apple Business Manager")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    
                    Button(action: { viewModel.connectToABM() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                            Text("Refresh All")
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.clientAssertion == nil || viewModel.isLoading)
                }
                .padding(.bottom, 4)
                
                // Stats Cards
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 16) {
                    StatCard(
                        title: "Total Devices",
                        value: "\(viewModel.devices.count)",
                        icon: "laptopcomputer.and.iphone",
                        color: .blue
                    )
                    
                    StatCard(
                        title: "MDM Servers",
                        value: "\(viewModel.mdmServers.count)",
                        icon: "server.rack",
                        color: .purple
                    )
                }
                .padding(.horizontal, 2) // Small padding to prevent shadow clipping
                
                // Device Breakdown
                if !viewModel.devices.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Device Breakdown")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        HStack(spacing: 16) {
                            DeviceTypeCard(
                                type: "Mac",
                                count: viewModel.devices.filter { 
                                    $0.os?.lowercased() == "mac"
                                }.count,
                                icon: "desktopcomputer",
                                color: .gray
                            )
                            DeviceTypeCard(
                                type: "iPhone",
                                count: viewModel.devices.filter { 
                                    $0.os?.lowercased() == "iphone"
                                }.count,
                                icon: "iphone",
                                color: .blue
                            )
                            DeviceTypeCard(
                                type: "iPad",
                                count: viewModel.devices.filter { 
                                    $0.os?.lowercased() == "ipad"
                                }.count,
                                icon: "ipad",
                                color: .indigo
                            )
                            DeviceTypeCard(
                                type: "Apple TV",
                                count: viewModel.devices.filter { 
                                    $0.os?.lowercased() == "appletv"
                                }.count,
                                icon: "appletv",
                                color: .black
                            )
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(NSColor.controlBackgroundColor))
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                    )
                }
                
                // Quick Actions
                VStack(alignment: .leading, spacing: 16) {
                    Text("Quick Actions")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 16) {
                        QuickActionButton(
                            title: "Export Devices",
                            icon: "square.and.arrow.up",
                            color: .green
                        ) {
                            showingExporter = true
                        }
                        .disabled(viewModel.devices.isEmpty)
                        
                        QuickActionButton(
                            title: "Check Activity",
                            icon: "clock.arrow.circlepath",
                            color: .blue
                        ) {
                            onNavigateToActivity()
                        }
                        .disabled(viewModel.clientAssertion == nil)
                    }
                }
                .padding(.horizontal, 2) // Small padding to prevent shadow clipping
                
                // Status Message
                if let status = viewModel.statusMessage {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(status)
                            .font(.subheadline)
                        Spacer()
                        Button(action: {
                            viewModel.statusMessage = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                
                // Error Message
                if let error = viewModel.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.subheadline)
                        Spacer()
                        Button(action: {
                            viewModel.errorMessage = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                
                // Connection Status — only show if no profiles exist yet
                if viewModel.clientAssertion == nil && viewModel.savedProfiles.isEmpty {
                    HStack(spacing: 16) {
                        Image(systemName: "link.badge.plus")
                            .font(.system(size: 24))
                            .foregroundStyle(.orange.gradient)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color.orange.opacity(0.1)))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Connect to Apple Business Manager")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Text("Configure your ABM API credentials")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Configure", action: onOpenSettings)
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(NSColor.controlBackgroundColor))
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 24)
        }
        .scrollContentBackground(.hidden)
        .background(Color(NSColor.windowBackgroundColor))
        .fileExporter(
            isPresented: $showingExporter,
            document: CSVDocument(devices: viewModel.devices),
            contentType: .commaSeparatedText,
            defaultFilename: "ABMate_devices_\(Date().formatted(date: .abbreviated, time: .omitted)).csv"
        ) { result in
            switch result {
            case .success(let url):
                viewModel.statusMessage = "Exported to \(url.lastPathComponent)"
            case .failure(let error):
                viewModel.errorMessage = "Export failed: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Device Type Card
struct DeviceTypeCard: View {
    let type: String
    let count: Int
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(color.gradient)
            }
            
            Text("\(count)")
                .font(.system(size: 24, weight: .bold, design: .rounded))
            Text(type)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(color.gradient)
                }
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 8)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Empty State Card
struct EmptyStateCard: View {
    let title: String
    let message: String
    let icon: String
    let actionLabel: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: action) {
                Text(actionLabel)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.05))
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Devices View
struct DevicesView: View {
    @ObservedObject var viewModel: ABMViewModel
    @State private var selectedDeviceIds = Set<OrgDevice.ID>()
    @State private var detailDevice: OrgDevice?
    @State private var searchText = ""
    @State private var showingExporter = false
    @State private var filterOS = "All"
    @State private var sortOrder = [KeyPathComparator(\OrgDevice.sortableAddedDate, order: .reverse)]
    @State private var displayedDevices: [OrgDevice] = []
    @State private var formattedAddedDates: [String: String] = [:]
    @State private var formattedUpdatedDates: [String: String] = [:]

    private func updateDisplayedDevices() {
        var devices = viewModel.devices

        if filterOS != "All" {
            let target: String
            switch filterOS {
            case "Apple TV": target = "appletv"
            default: target = filterOS.lowercased()
            }
            devices = devices.filter { ($0.os?.lowercased() ?? "") == target }
        }

        if !searchText.isEmpty {
            devices = devices.filter { device in
                device.serialNumber.localizedCaseInsensitiveContains(searchText) ||
                (device.model ?? "").localizedCaseInsensitiveContains(searchText) ||
                (device.productType ?? "").localizedCaseInsensitiveContains(searchText) ||
                (device.orderNumber ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }

        let sorted = devices.sorted(using: sortOrder)
        displayedDevices = sorted

        // Pre-cache formatted dates so cells don't recompute on every render
        var added = formattedAddedDates
        var updated = formattedUpdatedDates
        for device in sorted {
            if added[device.id] == nil {
                added[device.id] = OrgDevice.formatDate(device.addedDate)
            }
            if updated[device.id] == nil {
                updated[device.id] = OrgDevice.formatDate(device.updatedDate)
            }
        }
        formattedAddedDates = added
        formattedUpdatedDates = updated
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Devices")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("\(viewModel.devices.count) total devices")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 12) {
                        // Search
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Search...", text: $searchText)
                                .textFieldStyle(.plain)
                            if !searchText.isEmpty {
                                Button(action: { searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(8)
                        .frame(width: 220)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(NSColor.controlBackgroundColor))
                        )

                        // Filter
                        Picker("OS", selection: $filterOS) {
                            Text("All").tag("All")
                            Text("Mac").tag("Mac")
                            Text("iPhone").tag("iPhone")
                            Text("iPad").tag("iPad")
                            Text("Apple TV").tag("Apple TV")
                        }
                        .pickerStyle(.menu)
                        .frame(width: 100)

                        Button(action: { showingExporter = true }) {
                            Label("Export", systemImage: "square.and.arrow.up")
                        }
                        .disabled(viewModel.devices.isEmpty)

                        Button(action: { viewModel.fetchDevices() }) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .padding(20)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Content
            if viewModel.devices.isEmpty {
                Spacer()
                ContentUnavailableView(
                    "No Devices",
                    systemImage: "laptopcomputer.and.iphone",
                    description: Text("Connect to ABM to load your devices")
                )
                Spacer()
            } else if displayedDevices.isEmpty {
                Spacer()
                ContentUnavailableView.search(text: searchText)
                Spacer()
            } else {
                Table(displayedDevices, selection: $selectedDeviceIds, sortOrder: $sortOrder) {
                    TableColumn("Model", value: \.sortableModel) { device in
                        HStack(spacing: 8) {
                            Image(systemName: deviceIcon(for: device))
                                .foregroundColor(.blue)
                                .frame(width: 16)
                            Text(device.model ?? device.serialNumber)
                                .lineLimit(1)
                        }
                    }
                    .width(min: 140, ideal: 180)

                    TableColumn("Serial Number", value: \.serialNumber) { device in
                        Text(device.serialNumber)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    .width(min: 110, ideal: 130)

                    TableColumn("OS", value: \.sortableOS) { device in
                        Text(device.os ?? "—")
                            .lineLimit(1)
                    }
                    .width(min: 60, ideal: 70)

                    TableColumn("Product Type", value: \.sortableProductType) { device in
                        Text(device.productType ?? "—")
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .width(min: 100, ideal: 130)

                    TableColumn("Status", value: \.sortableStatus) { device in
                        let status = device.enrollmentState ?? "Unknown"
                        let color: Color = {
                            switch status.uppercased() {
                            case "ASSIGNED": return .green
                            case "UNASSIGNED": return .orange
                            default: return .gray
                            }
                        }()
                        Text(status)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(color.opacity(0.15)))
                            .foregroundColor(color)
                    }
                    .width(min: 90, ideal: 100)

                    TableColumn("Added", value: \.sortableAddedDate) { device in
                        Text(formattedAddedDates[device.id] ?? "—")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    .width(min: 85, ideal: 100)

                }
                .tableStyle(.inset(alternatesRowBackgrounds: true))
                .contextMenu(forSelectionType: OrgDevice.ID.self) { ids in
                    if let id = ids.first, let device = viewModel.devices.first(where: { $0.id == id }) {
                        Button("View Details") {
                            detailDevice = device
                        }
                        Button("Copy Serial Number") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(device.serialNumber, forType: .string)
                        }
                    }
                } primaryAction: { ids in
                    if let id = ids.first, let device = viewModel.devices.first(where: { $0.id == id }) {
                        detailDevice = device
                    }
                }
            }

            // Status Bar
            HStack {
                Text("\(displayedDevices.count) of \(viewModel.devices.count) devices")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if filterOS != "All" || !searchText.isEmpty {
                    Button("Clear Filters") {
                        filterOS = "All"
                        searchText = ""
                    }
                    .font(.caption)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
        }
        .onAppear { updateDisplayedDevices() }
        .onChange(of: sortOrder) { _, _ in
            // Disable implicit animations — animating 1,000+ rows repositioning is extremely slow
            var transaction = Transaction(animation: nil)
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                updateDisplayedDevices()
            }
        }
        .onChange(of: filterOS) { _, _ in updateDisplayedDevices() }
        .onChange(of: searchText) { _, _ in updateDisplayedDevices() }
        .onChange(of: viewModel.devices) { _, _ in updateDisplayedDevices() }
        .sheet(item: $detailDevice) { device in
            DeviceDetailSheet(device: device, viewModel: viewModel)
        }
        .fileExporter(
            isPresented: $showingExporter,
            document: CSVDocument(devices: displayedDevices),
            contentType: .commaSeparatedText,
            defaultFilename: "ABMate_devices_\(Date().formatted(date: .abbreviated, time: .omitted)).csv"
        ) { result in
            switch result {
            case .success(let url):
                viewModel.statusMessage = "Exported to \(url.lastPathComponent)"
            case .failure(let error):
                viewModel.errorMessage = "Export failed: \(error.localizedDescription)"
            }
        }
    }

    private func deviceIcon(for device: OrgDevice) -> String {
        switch device.os?.lowercased() {
        case "iphone": return "iphone"
        case "ipad": return "ipad"
        case "mac": return "desktopcomputer"
        case "appletv": return "appletv"
        default: return "questionmark.square"
        }
    }
}

// MARK: - Device Detail Sheet
struct DeviceDetailSheet: View {
    let device: OrgDevice
    @ObservedObject var viewModel: ABMViewModel
    @Environment(\.dismiss) var dismiss
    @State private var assignedServer: String?
    @State private var appleCareCoverages: [AppleCareCoverage] = []
    @State private var isLoadingAppleCare = false
    @State private var isLoadingServer = false
    @State private var appleCareError: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(device.model ?? device.serialNumber)
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Device Details")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Device Info Grid
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Device Information")
                            .font(.headline)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            DetailItem(label: "Serial Number", value: device.serialNumber)
                            DetailItem(label: "Model", value: device.model ?? "N/A")
                            DetailItem(label: "Product Family", value: device.os ?? "N/A")
                            DetailItem(label: "Product Type", value: device.productType ?? "N/A")
                            DetailItem(label: "Status", value: device.enrollmentState ?? "N/A")
                            if let capacity = device.capacity, !capacity.isEmpty {
                                DetailItem(label: "Capacity", value: capacity)
                            }
                            if let color = device.color, !color.isEmpty {
                                DetailItem(label: "Color", value: color)
                            }
                            if let orderNumber = device.orderNumber, !orderNumber.isEmpty {
                                DetailItem(label: "Order Number", value: orderNumber)
                            }
                            DetailItem(label: "Added to Org", value: OrgDevice.formatDate(device.addedDate))
                            DetailItem(label: "Last Updated", value: OrgDevice.formatDate(device.updatedDate))
                            DetailItem(label: "Device ID", value: device.id, monospaced: true)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(NSColor.controlBackgroundColor))
                    )
                    
                    // Assigned Server Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Assigned MDM Server")
                                .font(.headline)
                            Spacer()
                            if isLoadingServer {
                                ProgressView()
                                    .scaleEffect(0.7)
                            }
                        }
                        
                        if let server = assignedServer {
                            HStack {
                                Image(systemName: "server.rack")
                                    .foregroundColor(.purple)
                                Text(server)
                                    .font(.body)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.purple.opacity(0.1))
                            )
                        } else if !isLoadingServer {
                            Button(action: loadAssignedServer) {
                                Label("Get Assigned Server", systemImage: "server.rack")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(NSColor.controlBackgroundColor))
                    )
                    
                    // AppleCare Coverage Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("AppleCare Coverage")
                                .font(.headline)
                            Spacer()
                            if isLoadingAppleCare {
                                ProgressView()
                                    .scaleEffect(0.7)
                            }
                        }

                        if !appleCareCoverages.isEmpty {
                            ForEach(appleCareCoverages) { coverage in
                                VStack(alignment: .leading, spacing: 8) {
                                    // Coverage type header (e.g. "AppleCare" or "Limited Warranty")
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(coverage.attributes.status == "ACTIVE" ? Color.green : Color.orange)
                                            .frame(width: 8, height: 8)
                                        Text(coverage.attributes.description ?? coverage.type)
                                            .font(.system(.subheadline, weight: .semibold))
                                        Spacer()
                                        Text(coverage.attributes.status ?? "Unknown")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(
                                                Capsule()
                                                    .fill((coverage.attributes.status == "ACTIVE" ? Color.green : Color.orange).opacity(0.15))
                                            )
                                            .foregroundColor(coverage.attributes.status == "ACTIVE" ? .green : .orange)
                                    }

                                    LazyVGrid(columns: [
                                        GridItem(.flexible()),
                                        GridItem(.flexible())
                                    ], spacing: 8) {
                                        if let start = coverage.attributes.startDateTime {
                                            DetailItem(label: "Start Date", value: String(start.prefix(10)))
                                        }
                                        if let end = coverage.attributes.endDateTime {
                                            DetailItem(label: "End Date", value: String(end.prefix(10)))
                                        }
                                        if let agreement = coverage.attributes.agreementNumber {
                                            DetailItem(label: "Agreement #", value: agreement)
                                        }
                                        if let renewable = coverage.attributes.isRenewable {
                                            DetailItem(label: "Renewable", value: renewable ? "Yes" : "No")
                                        }
                                    }
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                            }
                        } else if let error = appleCareError {
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.orange)
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.orange.opacity(0.1))
                            )
                        } else if !isLoadingAppleCare {
                            Button(action: loadAppleCare) {
                                Label("Check AppleCare Coverage", systemImage: "checkmark.shield")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(NSColor.controlBackgroundColor))
                    )
                }
                .padding(20)
            }
        }
        .frame(width: 560, height: 680)
        .onAppear {
            // Auto-load MDM server on appear
            loadAssignedServer()
        }
    }
    
    private func loadAssignedServer() {
        guard !isLoadingServer else { return }
        isLoadingServer = true
        Task { @MainActor in
            let server = await viewModel.getDeviceAssignedServer(deviceId: device.id)
            assignedServer = server
            isLoadingServer = false
        }
    }
    
    private func loadAppleCare() {
        guard !isLoadingAppleCare else { return }
        isLoadingAppleCare = true
        appleCareError = nil
        Task { @MainActor in
            print("Loading AppleCare for device: \(device.id)")
            let coverages = await viewModel.getAppleCareCoverage(deviceId: device.id)
            if !coverages.isEmpty {
                print("Got \(coverages.count) AppleCare coverage entries")
                appleCareCoverages = coverages
            } else {
                print("No AppleCare coverage returned")
                appleCareError = viewModel.errorMessage ?? "No coverage information available for this device."
            }
            isLoadingAppleCare = false
        }
    }
}

// Coverage Item with status indicator
struct CoverageItem: View {
    let label: String
    let value: String
    let isActive: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            HStack(spacing: 6) {
                Circle()
                    .fill(isActive ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
                Text(value)
                    .font(.body)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Detail Item
struct DetailItem: View {
    let label: String
    let value: String
    var monospaced: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(monospaced ? .system(.body, design: .monospaced) : .body)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - MDM Servers View
struct MDMServersView: View {
    @ObservedObject var viewModel: ABMViewModel
    @State private var selectedServer: MDMServer?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("MDM Servers")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("\(viewModel.mdmServers.count) registered servers")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(20)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            if viewModel.mdmServers.isEmpty {
                Spacer()
                ContentUnavailableView(
                    "No MDM Servers",
                    systemImage: "server.rack",
                    description: Text("Connect to ABM to load your MDM servers")
                )
                Spacer()
            } else {
                List(viewModel.mdmServers, selection: $selectedServer) { server in
                    MDMServerRow(server: server)
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
                
                if let server = selectedServer {
                    HStack {
                        Text("Selected: \(server.attributes.serverName)")
                            .font(.headline)
                        Spacer()
                        Button("Get Devices") {
                            Task {
                                await viewModel.getDevicesForMDM(mdmId: server.id)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(16)
                    .background(Color(NSColor.controlBackgroundColor))
                }
            }
        }
    }
}

// MARK: - MDM Server Row
struct MDMServerRow: View {
    let server: MDMServer
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.purple.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: "server.rack")
                    .font(.title3)
                    .foregroundColor(.purple)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(server.attributes.serverName)
                    .font(.system(.body, weight: .medium))
                Text(server.attributes.serverType)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(server.id)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Device Assignment View
struct DeviceAssignmentView: View {
    @ObservedObject var viewModel: ABMViewModel
    @State private var selectedDevices: Set<String> = []
    @State private var selectedMDM: String = ""
    @State private var actionType = "ASSIGN"
    @State private var searchText = ""
    @State private var showingConfirmation = false

    var filteredDevices: [OrgDevice] {
        if searchText.isEmpty {
            return viewModel.devices
        }
        let query = searchText.lowercased()
        return viewModel.devices.filter { device in
            let model = (device.model ?? "").lowercased()
            let serial = device.serialNumber.lowercased()
            let productType = (device.productType ?? "").lowercased()
            return model.contains(query) || serial.contains(query) || productType.contains(query)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Assign Devices")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Bulk assign or unassign devices to MDM servers")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(20)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Action Type
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Action")
                            .font(.headline)
                        
                        Picker("Action", selection: $actionType) {
                            Label("Assign to MDM", systemImage: "arrow.right.circle").tag("ASSIGN")
                            Label("Unassign from MDM", systemImage: "arrow.left.circle").tag("UNASSIGN")
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    // MDM Server Selection
                    if actionType == "ASSIGN" {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Target MDM Server")
                                .font(.headline)
                            
                            Picker("MDM Server", selection: $selectedMDM) {
                                Text("Select a server...").tag("")
                                ForEach(viewModel.mdmServers) { server in
                                    Text(server.attributes.serverName).tag(server.id)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }
                    
                    // Device Selection
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Select Devices")
                                .font(.headline)
                            Spacer()
                            Text("\(selectedDevices.count) selected")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        // Search Bar
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Search by model, serial number, or product type...", text: $searchText)
                                .textFieldStyle(.plain)
                            if !searchText.isEmpty {
                                Button(action: { searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(NSColor.controlBackgroundColor))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                        )

                        if viewModel.devices.isEmpty {
                            Text("No devices available. Connect to ABM first.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding()
                        } else if filteredDevices.isEmpty {
                            Text("No devices match \"\(searchText)\"")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            HStack {
                                Text("\(filteredDevices.count) device\(filteredDevices.count == 1 ? "" : "s") shown")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }

                            List(filteredDevices, selection: $selectedDevices) { device in
                                HStack {
                                    Text(device.model ?? device.serialNumber)
                                    Spacer()
                                    Text(device.serialNumber)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .listStyle(.bordered)
                            .frame(height: 250)
                        }
                    }
                    
                    // Execute Button
                    Button(action: {
                        showingConfirmation = true
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .frame(width: 16, height: 16)
                            } else {
                                Image(systemName: "bolt.fill")
                            }
                            Text(viewModel.isLoading ? "Processing..." : "Execute \(actionType == "ASSIGN" ? "Assignment" : "Unassignment")")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(selectedDevices.isEmpty || (actionType == "ASSIGN" && selectedMDM.isEmpty) || viewModel.isLoading)
                    .alert("Confirm \(actionType == "ASSIGN" ? "Assignment" : "Unassignment")", isPresented: $showingConfirmation) {
                        Button("Cancel", role: .cancel) { }
                        Button(actionType == "ASSIGN" ? "Assign" : "Unassign", role: .destructive) {
                            Task {
                                await viewModel.assignDevices(
                                    deviceIds: Array(selectedDevices),
                                    mdmId: actionType == "ASSIGN" ? selectedMDM : nil
                                )
                            }
                        }
                    } message: {
                        if actionType == "ASSIGN" {
                            let serverName = viewModel.mdmServers.first(where: { $0.id == selectedMDM })?.attributes.serverName ?? "selected server"
                            Text("Are you sure you want to assign \(selectedDevices.count) device\(selectedDevices.count == 1 ? "" : "s") to \(serverName)?")
                        } else {
                            Text("Are you sure you want to unassign \(selectedDevices.count) device\(selectedDevices.count == 1 ? "" : "s") from their MDM server?")
                        }
                    }
                    
                    // Status Message
                    if let status = viewModel.statusMessage {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(status)
                                .font(.subheadline)
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.green.opacity(0.1))
                        )
                    }
                    
                    // Error Message
                    if let error = viewModel.errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(error)
                                .font(.subheadline)
                            Spacer()
                            Button(action: {
                                viewModel.errorMessage = nil
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.orange.opacity(0.1))
                        )
                    }
                }
                .padding(24)
                .padding(.bottom, 80) // Add bottom padding to scrollable content
            }
        }
    }
}

// MARK: - Activity Status View
struct ActivityStatusView: View {
    @ObservedObject var viewModel: ABMViewModel
    @State private var activityId = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Activity Status")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Track batch operation progress")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(20)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Activity ID Input
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Check Activity")
                            .font(.headline)
                        
                        HStack(spacing: 12) {
                            TextField("Enter Activity ID...", text: $activityId)
                                .textFieldStyle(.roundedBorder)
                            
                            Button("Check Status") {
                                Task {
                                    await viewModel.checkActivityStatus(activityId: activityId)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(activityId.isEmpty)
                        }
                    }
                    
                    // Last Activity
                    if let lastId = viewModel.lastActivityId {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Activity")
                                .font(.headline)
                            
                            HStack {
                                Text(lastId)
                                    .font(.system(.body, design: .monospaced))
                                    .textSelection(.enabled)
                                Spacer()
                                Button("Check") {
                                    activityId = lastId
                                    Task {
                                        await viewModel.checkActivityStatus(activityId: lastId)
                                    }
                                }
                                .buttonStyle(.bordered)
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(NSColor.controlBackgroundColor))
                            )
                        }
                    }
                    
                    // Activity Result
                    if let status = viewModel.activityStatus {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Activity Details")
                                .font(.headline)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 16) {
                                DetailItem(label: "Activity ID", value: status.data.id, monospaced: true)
                                DetailItem(label: "Status", value: status.data.attributes.status)
                                DetailItem(label: "Sub-Status", value: status.data.attributes.subStatus)
                                DetailItem(label: "Created", value: status.data.attributes.createdDateTime)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(NSColor.controlBackgroundColor))
                            )
                        }
                    }
                }
                .padding(24)
                .padding(.bottom, 80) // Add bottom padding to scrollable content
            }
        }
    }
}

// MARK: - MDM Sync View (Jamf Pro)
struct JamfSyncView: View {
    @ObservedObject var viewModel: ABMViewModel

    // Search
    @State private var serialSearch = ""
    @State private var isSearching = false

    // Results
    @State private var asmDevice: OrgDevice?
    @State private var asmCoverage: [AppleCareCoverage] = []
    @State private var jamfMatch: JamfDeviceMatch?
    @State private var searchError: String?
    @State private var searchCompleted = false

    // Sync
    @State private var isSyncing = false
    @State private var syncSuccess: String?
    @State private var syncError: String?

    // Editable fields for the sync payload
    @State private var poNumber = ""
    @State private var poDate = ""
    @State private var vendor = ""
    @State private var warrantyDate = ""
    @State private var appleCareId = ""
    @State private var leaseDate = ""
    @State private var purchasePrice = ""
    @State private var lifeExpectancy = ""
    @State private var purchasingAccount = ""
    @State private var purchasingContact = ""
    @State private var isPurchased = true
    @State private var isLeased = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("MDM Sync")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                        Text("Sync purchasing data from ASM to Jamf Pro")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.bottom, 4)

                // Connection Status
                HStack(spacing: 16) {
                    connectionPill(label: "ASM", connected: viewModel.isConnected, icon: "apple.logo")
                    connectionPill(label: "Jamf Pro", connected: viewModel.isJamfConnected, icon: "server.rack")
                }

                if !viewModel.isConnected || !viewModel.isJamfConnected {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Both ASM and Jamf Pro connections are required. Open Connection Settings to configure.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.orange.opacity(0.1))
                    )
                }

                // Search Section
                VStack(alignment: .leading, spacing: 12) {
                    Label("Device Lookup", systemImage: "magnifyingglass")
                        .font(.headline)

                    HStack(spacing: 12) {
                        HStack(spacing: 10) {
                            Image(systemName: "barcode")
                                .foregroundColor(.secondary)
                            TextField("Enter serial number...", text: $serialSearch)
                                .textFieldStyle(.plain)
                                .font(.system(.body, design: .monospaced))
                                .onSubmit { performSearch() }
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(NSColor.controlBackgroundColor))
                        )

                        Button(action: performSearch) {
                            HStack(spacing: 6) {
                                if isSearching {
                                    ProgressView()
                                        .scaleEffect(0.6)
                                } else {
                                    Image(systemName: "magnifyingglass")
                                }
                                Text("Search")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(serialSearch.trimmingCharacters(in: .whitespaces).isEmpty || isSearching || !viewModel.isConnected || !viewModel.isJamfConnected)
                    }

                    Text("Searches for the device in your loaded ASM data and in Jamf Pro inventory.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Error
                if let error = searchError {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.orange.opacity(0.1)))
                }

                // Results
                if searchCompleted {
                    if asmDevice != nil || jamfMatch != nil {
                        // Side-by-side results
                        HStack(alignment: .top, spacing: 16) {
                            // ASM side
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 6) {
                                    Image(systemName: "apple.logo")
                                        .foregroundColor(.blue)
                                    Text("ASM Data")
                                        .font(.headline)
                                    Spacer()
                                    if asmDevice != nil {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.caption)
                                    } else {
                                        Text("Not Found")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                }

                                if let device = asmDevice {
                                    VStack(spacing: 8) {
                                        syncDetailRow("Serial", device.serialNumber)
                                        syncDetailRow("Model", device.model ?? "—")
                                        syncDetailRow("Type", device.productType ?? "—")
                                        syncDetailRow("Order #", device.orderNumber ?? "—")
                                        syncDetailRow("Status", device.enrollmentState ?? "—")
                                        syncDetailRow("Added", OrgDevice.formatDate(device.addedDate))
                                    }

                                    if !asmCoverage.isEmpty {
                                        Divider()
                                        Text("AppleCare Coverage")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        ForEach(asmCoverage) { cov in
                                            VStack(spacing: 4) {
                                                syncDetailRow("Type", cov.attributes.description ?? "—")
                                                syncDetailRow("Status", cov.attributes.status ?? "—")
                                                syncDetailRow("Agreement #", cov.attributes.agreementNumber ?? "—")
                                                syncDetailRow("Ends", OrgDevice.formatDate(cov.attributes.endDateTime))
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue.opacity(0.03))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.blue.opacity(0.15), lineWidth: 1))
                            )

                            // Jamf side
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 6) {
                                    Image(systemName: "server.rack")
                                        .foregroundColor(.orange)
                                    Text("Jamf Pro Data")
                                        .font(.headline)
                                    Spacer()
                                    if jamfMatch != nil {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.caption)
                                    } else {
                                        Text("Not Found")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                }

                                if let match = jamfMatch {
                                    VStack(spacing: 8) {
                                        syncDetailRow("Name", match.name)
                                        syncDetailRow("Serial", match.serial)
                                        syncDetailRow("Model", match.model)
                                        syncDetailRow("Type", match.deviceType.rawValue)
                                    }

                                    if let p = match.currentPurchasing {
                                        Divider()
                                        Text("Current Purchasing")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        VStack(spacing: 4) {
                                            syncDetailRow("PO #", p.poNumber ?? "—")
                                            syncDetailRow("Vendor", p.vendor ?? "—")
                                            syncDetailRow("Warranty", p.warrantyDate ?? "—")
                                            syncDetailRow("AppleCare ID", p.appleCareId ?? "—")
                                            syncDetailRow("Price", p.purchasePrice ?? "—")
                                        }
                                    }
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.orange.opacity(0.03))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.orange.opacity(0.15), lineWidth: 1))
                            )
                        }

                        // Sync Form — editable fields to push
                        if asmDevice != nil && jamfMatch != nil {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Data to Sync to Jamf Pro")
                                        .font(.headline)
                                }

                                Text("Review and edit the values below before pushing to Jamf. Fields are pre-populated from ASM data.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                    syncField("PO Number", $poNumber)
                                    syncField("PO Date", $poDate)
                                    syncField("Vendor", $vendor)
                                    syncField("Warranty Expiration", $warrantyDate)
                                    syncField("AppleCare ID", $appleCareId)
                                    syncField("Lease Expiration", $leaseDate)
                                    syncField("Purchase Price", $purchasePrice)
                                    syncField("Life Expectancy (years)", $lifeExpectancy)
                                    syncField("Purchasing Account", $purchasingAccount)
                                    syncField("Purchasing Contact", $purchasingContact)
                                }

                                HStack(spacing: 16) {
                                    Toggle("Purchased", isOn: $isPurchased)
                                    Toggle("Leased", isOn: $isLeased)
                                }
                                .font(.subheadline)

                                // Sync Button
                                HStack {
                                    Spacer()
                                    Button(action: performSync) {
                                        HStack(spacing: 8) {
                                            if isSyncing {
                                                ProgressView()
                                                    .scaleEffect(0.7)
                                            } else {
                                                Image(systemName: "arrow.triangle.2.circlepath")
                                            }
                                            Text("Push to Jamf Pro")
                                        }
                                        .padding(.horizontal, 24)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.green)
                                    .controlSize(.large)
                                    .disabled(isSyncing)
                                    Spacer()
                                }

                                // Sync Status
                                if let success = syncSuccess {
                                    HStack(spacing: 8) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text(success)
                                            .font(.subheadline)
                                    }
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.green.opacity(0.1)))
                                }

                                if let error = syncError {
                                    HStack(spacing: 8) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                        Text(error)
                                            .font(.subheadline)
                                    }
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.red.opacity(0.1)))
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.green.opacity(0.03))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.green.opacity(0.15), lineWidth: 1))
                            )
                        }
                    }
                }
            }
            .padding(24)
            .padding(.bottom, 80)
        }
    }

    // MARK: - Helpers

    private func connectionPill(label: String, connected: Bool, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
            Text(label)
                .font(.system(size: 13, weight: .medium))
            Circle()
                .fill(connected ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            Text(connected ? "Connected" : "Disconnected")
                .font(.system(size: 11))
                .foregroundColor(connected ? .green : .red)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(connected ? Color.green.opacity(0.06) : Color.red.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(connected ? Color.green.opacity(0.2) : Color.red.opacity(0.2), lineWidth: 1))
        )
    }

    private func syncDetailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 90, alignment: .trailing)
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .lineLimit(1)
            Spacer()
        }
    }

    private func syncField(_ label: String, _ binding: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            TextField(label, text: binding)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
        }
    }

    // MARK: - Search

    private func performSearch() {
        let serial = serialSearch.trimmingCharacters(in: .whitespaces).uppercased()
        guard !serial.isEmpty else { return }

        isSearching = true
        searchError = nil
        searchCompleted = false
        asmDevice = nil
        asmCoverage = []
        jamfMatch = nil
        syncSuccess = nil
        syncError = nil

        // Reset editable fields
        poNumber = ""
        poDate = ""
        vendor = ""
        warrantyDate = ""
        appleCareId = ""
        leaseDate = ""
        purchasePrice = ""
        lifeExpectancy = ""
        purchasingAccount = ""
        purchasingContact = ""
        isPurchased = true
        isLeased = false

        Task {
            // 1. Look up in ASM (from loaded devices)
            let foundASM = viewModel.devices.first(where: { $0.serialNumber.uppercased() == serial })
            asmDevice = foundASM

            // 2. Fetch AppleCare coverage if ASM device found
            if let device = foundASM {
                if let token = await viewModel.getCurrentAccessToken() {
                    do {
                        asmCoverage = try await viewModel.apiService.getAppleCareCoverage(
                            deviceId: device.id,
                            accessToken: token
                        )
                    } catch {
                        print("AppleCare lookup failed: \(error)")
                        // Non-fatal — continue without coverage
                    }
                }
            }

            // 3. Look up in Jamf Pro
            do {
                let token = try await viewModel.getJamfToken()
                jamfMatch = try await viewModel.jamfAPIService.findDeviceBySerial(serial, token: token)
            } catch {
                searchError = "Jamf lookup failed: \(error.localizedDescription)"
            }

            if asmDevice == nil && jamfMatch == nil && searchError == nil {
                searchError = "Serial \"\(serial)\" not found in ASM data or Jamf Pro inventory."
            }

            // Pre-populate sync fields from ASM data
            if let device = foundASM {
                poNumber = device.orderNumber ?? ""
            }

            // Use AppleCare coverage for warranty info
            if let activeCoverage = asmCoverage.first(where: { $0.attributes.status == "ACTIVE" }) ?? asmCoverage.first {
                appleCareId = activeCoverage.attributes.agreementNumber ?? ""
                if let endDate = activeCoverage.attributes.endDateTime {
                    warrantyDate = String(endDate.prefix(10))
                }
            }

            // Default vendor
            if vendor.isEmpty { vendor = "Apple" }

            searchCompleted = true
            isSearching = false
        }
    }

    // MARK: - Sync

    private func performSync() {
        guard let match = jamfMatch else { return }

        isSyncing = true
        syncSuccess = nil
        syncError = nil

        let purchasing = JamfPurchasing(
            purchased: isPurchased,
            leased: isLeased,
            poNumber: poNumber.isEmpty ? nil : poNumber,
            poDate: poDate.isEmpty ? nil : poDate,
            vendor: vendor.isEmpty ? nil : vendor,
            warrantyDate: warrantyDate.isEmpty ? nil : warrantyDate,
            appleCareId: appleCareId.isEmpty ? nil : appleCareId,
            leaseDate: leaseDate.isEmpty ? nil : leaseDate,
            purchasePrice: purchasePrice.isEmpty ? nil : purchasePrice,
            lifeExpectancy: lifeExpectancy.isEmpty ? nil : Int(lifeExpectancy),
            purchasingAccount: purchasingAccount.isEmpty ? nil : purchasingAccount,
            purchasingContact: purchasingContact.isEmpty ? nil : purchasingContact
        )

        Task {
            do {
                let token = try await viewModel.getJamfToken()
                try await viewModel.jamfAPIService.updateDevicePurchasing(
                    match: match,
                    purchasing: purchasing,
                    token: token
                )
                syncSuccess = "Successfully synced purchasing data to Jamf Pro for \(match.serial) (\(match.name))."
            } catch {
                syncError = "Sync failed: \(error.localizedDescription)"
            }
            isSyncing = false
        }
    }
}

