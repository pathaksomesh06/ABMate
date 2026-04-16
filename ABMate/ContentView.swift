//
//  ContentView.swift
//  ABMate
//
//  © Created by Somesh Pathak on 23/06/2025.
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Theme
private enum AppTheme {
    static let accent = Color(red: 0.23, green: 0.45, blue: 0.96)
    static let accentSoft = Color(red: 0.42, green: 0.62, blue: 0.98)
    static let success = Color(red: 0.22, green: 0.71, blue: 0.45)
    static let warning = Color(red: 0.95, green: 0.62, blue: 0.18)
    static let error = Color(red: 0.91, green: 0.31, blue: 0.24)
    static let info = Color(red: 0.32, green: 0.58, blue: 0.98)

    static let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.95, green: 0.97, blue: 1.0),
            Color(red: 0.93, green: 0.95, blue: 0.98),
            Color(red: 0.91, green: 0.94, blue: 0.98)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Navigation
enum NavigationItem: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case devices = "Devices"
    case mdmServers = "MDM Servers"
    case assign = "Assign"
    case activity = "Activity"
    // ABM-only
    case users = "Users"
    case apps = "Apps"
    case blueprints = "Blueprints"
    case configurations = "Configurations"
    case auditEvents = "Audit Events"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2"
        case .devices: return "laptopcomputer.and.iphone"
        case .mdmServers: return "server.rack"
        case .assign: return "arrow.triangle.swap"
        case .activity: return "clock.arrow.circlepath"
        case .users: return "person.2"
        case .apps: return "app.badge"
        case .blueprints: return "doc.text.magnifyingglass"
        case .configurations: return "gearshape.2"
        case .auditEvents: return "list.bullet.clipboard"
        }
    }
    
    /// Whether this item requires Apple Business Manager (not available in ASM).
    var isABMOnly: Bool {
        switch self {
        case .users, .apps, .blueprints, .configurations, .auditEvents:
            return true
        default:
            return false
        }
    }
    
    /// Returns navigation items available for the given platform.
    static func items(for platform: ApplePlatform) -> [NavigationItem] {
        allCases.filter { !$0.isABMOnly || platform == .business }
    }
}

private struct MaterialCardStyle: ViewModifier {
    let cornerRadius: CGFloat
    let material: Material
    let strokeOpacity: Double
    let shadowOpacity: Double

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(material)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(strokeOpacity), lineWidth: 1)
            )
            .shadow(color: .black.opacity(shadowOpacity), radius: 10, x: 0, y: 4)
    }
}

private extension View {
    func materialCard(
        cornerRadius: CGFloat = 12,
        material: Material = .regularMaterial,
        strokeOpacity: Double = 0.12,
        shadowOpacity: Double = 0.08
    ) -> some View {
        modifier(MaterialCardStyle(
            cornerRadius: cornerRadius,
            material: material,
            strokeOpacity: strokeOpacity,
            shadowOpacity: shadowOpacity
        ))
    }

    func materialInsetField(cornerRadius: CGFloat = 8) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
    }

    func staggeredAppear(isVisible: Bool, delay: Double) -> some View {
        opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 10)
            .animation(.easeOut(duration: 0.35).delay(delay), value: isVisible)
    }
}

// MARK: - Main Content View
struct ContentView: View {
    @StateObject private var viewModel = ABMViewModel()
    @State private var selectedNavItem: NavigationItem = .dashboard
    @State private var showingSettings = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .doubleColumn
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()

            Circle()
                .fill(AppTheme.accentSoft.opacity(0.18))
                .frame(width: 520, height: 520)
                .blur(radius: 70)
                .offset(x: 240, y: -240)

            NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar
            VStack(spacing: 0) {
                // App Header
                HStack(spacing: 10) {
                    Image(systemName: "apple.terminal")
                        .font(.title2)
                        .foregroundStyle(AppTheme.accent.gradient)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ABMate")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                        Text("v1.0")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        Text(viewModel.platform.shortName)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Connection Status Badge
                    ConnectionBadge(isConnected: viewModel.clientAssertion != nil)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                Divider()
                    .padding(.horizontal, 12)
                
                // Navigation List
                List(NavigationItem.items(for: viewModel.platform), selection: $selectedNavItem) { item in
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
                case .users:
                    UsersView(viewModel: viewModel)
                case .apps:
                    AppsView(viewModel: viewModel)
                case .blueprints:
                    BlueprintsView(viewModel: viewModel)
                case .configurations:
                    ConfigurationsView(viewModel: viewModel)
                case .auditEvents:
                    AuditEventsView(viewModel: viewModel)
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
        .tint(AppTheme.accent)
    }
}

// MARK: - Connection Badge
struct ConnectionBadge: View {
    let isConnected: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isConnected ? AppTheme.success : AppTheme.warning)
                .frame(width: 6, height: 6)
            Text(isConnected ? "Connected" : "Offline")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(isConnected ? AppTheme.success.opacity(0.12) : AppTheme.warning.opacity(0.12))
        )
    }
}

// MARK: - Connection Settings Sheet
struct ConnectionSettingsSheet: View {
    @ObservedObject var viewModel: ABMViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingKeyImporter = false
    
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
                    // Platform Section
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Platform", systemImage: "building.2")
                            .font(.headline)
                        Picker("Platform", selection: $viewModel.platform) {
                            ForEach(ApplePlatform.allCases) { platform in
                                Text(platform.displayName)
                                    .tag(platform)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(16)
                    .materialCard(cornerRadius: 12, material: .regularMaterial, strokeOpacity: 0.12, shadowOpacity: 0.04)

                    // Credentials Section
                    VStack(alignment: .leading, spacing: 16) {
                        Label("API Credentials", systemImage: "key.fill")
                            .font(.headline)
                        
                        VStack(spacing: 12) {
                            CredentialField(
                                label: "Client ID",
                                placeholder: "BUSINESSAPI.xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
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
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .fill(.ultraThinMaterial)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .stroke(viewModel.privateKey.isEmpty ? AppTheme.info.opacity(0.35) : AppTheme.success.opacity(0.35), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(16)
                    .materialCard(cornerRadius: 14, material: .regularMaterial, strokeOpacity: 0.12, shadowOpacity: 0.05)
                    
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
                                Text("Connect to \(viewModel.platform.displayName)")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .disabled(viewModel.clientAssertion == nil || viewModel.isLoading)
                    }
                    .padding(16)
                    .materialCard(cornerRadius: 14, material: .regularMaterial, strokeOpacity: 0.12, shadowOpacity: 0.05)
                    
                    // Status Messages
                    if viewModel.isLoading || viewModel.statusMessage != nil || viewModel.errorMessage != nil || viewModel.warningMessage != nil {
                        StatusMessageView(
                            isLoading: viewModel.isLoading,
                            statusMessage: viewModel.statusMessage,
                            errorMessage: viewModel.errorMessage,
                            warningMessage: viewModel.warningMessage,
                            fetchProgress: viewModel.fetchProgress
                        )
                    }
                }
                .padding(20)
            }
        }
        .background(.ultraThinMaterial)
        .frame(width: 480, height: 520)
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
            if let message = newValue, message.contains("Connected to") {
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
            .materialInsetField(cornerRadius: 8)
        }
    }
}

// MARK: - Status Message View
struct StatusMessageView: View {
    let isLoading: Bool
    let statusMessage: String?
    let errorMessage: String?
    let warningMessage: String?
    var fetchProgress: Int = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.7)
                    if fetchProgress > 0 {
                        Text("Fetching devices… (\(fetchProgress.formatted()) so far)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Connecting...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if let status = statusMessage, !isLoading {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppTheme.success)
                    Text(status)
                        .font(.subheadline)
                }
            }
            
            if let warning = warningMessage {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(AppTheme.warning)
                    Text(warning)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            if let error = errorMessage {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(AppTheme.error)
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .materialCard(cornerRadius: 10, material: .ultraThinMaterial, strokeOpacity: 0.12, shadowOpacity: 0.03)
    }
}

// MARK: - Dashboard View
struct DashboardView: View {
    @ObservedObject var viewModel: ABMViewModel
    let onOpenSettings: () -> Void
    let onNavigateToActivity: () -> Void
    @State private var showingExporter = false
    @State private var hasAppeared = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Dashboard")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                        Text("Overview of your \(viewModel.platform.displayName)")
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
                    
                    if viewModel.platform.supportsUsers {
                        StatCard(
                            title: "Users",
                            value: "\(viewModel.users.count)",
                            icon: "person.2",
                            color: .orange
                        )
                    }
                    
                    if viewModel.platform.supportsApps {
                        StatCard(
                            title: "Apps",
                            value: "\(viewModel.apps.count)",
                            icon: "app.badge",
                            color: .green
                        )
                    }
                    
                    if viewModel.platform.supportsBlueprints {
                        StatCard(
                            title: "Blueprints",
                            value: "\(viewModel.blueprints.count)",
                            icon: "doc.text.magnifyingglass",
                            color: .teal
                        )
                    }
                    
                    if viewModel.platform.supportsConfigurations {
                        StatCard(
                            title: "Configurations",
                            value: "\(viewModel.configurations.count)",
                            icon: "gearshape.2",
                            color: .indigo
                        )
                    }
                }
                .padding(.horizontal, 2) // Small padding to prevent shadow clipping
                .staggeredAppear(isVisible: hasAppeared, delay: 0.05)
                
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
                    .materialCard(cornerRadius: 16, material: .regularMaterial, strokeOpacity: 0.12, shadowOpacity: 0.06)
                    .staggeredAppear(isVisible: hasAppeared, delay: 0.12)
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
                .staggeredAppear(isVisible: hasAppeared, delay: 0.18)
                
                // Status Message
                if let status = viewModel.statusMessage {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppTheme.success)
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
                            .fill(AppTheme.success.opacity(0.12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppTheme.success.opacity(0.35), lineWidth: 1)
                            )
                    )
                }
                
                // Error Message
                if let error = viewModel.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(AppTheme.error)
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
                            .fill(AppTheme.error.opacity(0.12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppTheme.error.opacity(0.35), lineWidth: 1)
                            )
                    )
                }
                
                // Connection Status
                if viewModel.clientAssertion == nil {
                    HStack(spacing: 16) {
                        Image(systemName: "link.badge.plus")
                            .font(.system(size: 24))
                            .foregroundStyle(.orange.gradient)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(AppTheme.warning.opacity(0.15)))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Connect to \(viewModel.platform.displayName)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Text("Configure your \(viewModel.platform.displayName) API credentials")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Configure", action: onOpenSettings)
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                    }
                    .padding(12)
                    .materialCard(cornerRadius: 10, material: .ultraThinMaterial, strokeOpacity: 0.12, shadowOpacity: 0.03)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 24)
        }
        .scrollContentBackground(.hidden)
        .background(.ultraThinMaterial)
        .onAppear {
            hasAppeared = true
        }
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
    @State private var isHovering = false
    
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
        .materialCard(cornerRadius: 12, material: .regularMaterial, strokeOpacity: 0.18, shadowOpacity: 0.06)
        .scaleEffect(isHovering ? 1.01 : 1)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.18)) {
                isHovering = hovering
            }
        }
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
        .padding(12)
        .materialCard(cornerRadius: 12, material: .ultraThinMaterial, strokeOpacity: 0.12, shadowOpacity: 0.03)
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    @State private var isHovering = false
    
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
            .materialCard(cornerRadius: 14, material: .regularMaterial, strokeOpacity: 0.16, shadowOpacity: 0.08)
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovering ? 1.02 : 1)
        .shadow(color: .black.opacity(isHovering ? 0.12 : 0.06), radius: isHovering ? 12 : 8, x: 0, y: 4)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.18)) {
                isHovering = hovering
            }
        }
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
        .materialCard(cornerRadius: 14, material: .ultraThinMaterial, strokeOpacity: 0.12, shadowOpacity: 0.04)
    }
}

// MARK: - Devices View
struct DevicesView: View {
    @ObservedObject var viewModel: ABMViewModel
    @State private var selectedDevice: OrgDevice?
    @State private var showingDetails = false
    @State private var searchText = ""
    @State private var showingExporter = false
    @State private var filterOS = "All"
    
    var filteredDevices: [OrgDevice] {
        var devices = viewModel.devices
        
        if filterOS != "All" {
            devices = devices.filter { device in
                let os = device.os?.lowercased() ?? ""
                switch filterOS {
                case "Mac":
                    return os == "mac"
                case "iPhone":
                    return os == "iphone"
                case "iPad":
                    return os == "ipad"
                case "Apple TV":
                    return os == "appletv"
                default:
                    return true
                }
            }
        }
        
        if !searchText.isEmpty {
            devices = devices.filter { device in
                device.serialNumber.localizedCaseInsensitiveContains(searchText) ||
                (device.model ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return devices
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
                        .materialInsetField(cornerRadius: 8)
                        
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
            .background(.ultraThinMaterial)
            
            Divider()
            
            // Content
            if viewModel.devices.isEmpty {
                Spacer()
                ContentUnavailableView(
                    "No Devices",
                    systemImage: "laptopcomputer.and.iphone",
                    description: Text("Connect to \(viewModel.platform.displayName) to load your devices")
                )
                Spacer()
            } else if filteredDevices.isEmpty {
                Spacer()
                ContentUnavailableView.search(text: searchText)
                Spacer()
            } else {
                List(filteredDevices, selection: $selectedDevice) { device in
                    DeviceRow(device: device)
                        .onTapGesture(count: 2) {
                            selectedDevice = device
                            showingDetails = true
                        }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
            
            // Status Bar
            HStack {
                Text("\(filteredDevices.count) of \(viewModel.devices.count) devices")
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
            .background(.thinMaterial)
        }
        .sheet(isPresented: $showingDetails) {
            if let device = selectedDevice {
                DeviceDetailSheet(device: device, viewModel: viewModel)
            }
        }
        .fileExporter(
            isPresented: $showingExporter,
            document: CSVDocument(devices: filteredDevices),
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

// MARK: - Device Row
struct DeviceRow: View {
    let device: OrgDevice
    
    var deviceIcon: String {
        switch device.os?.lowercased() {
        case "iphone": return "iphone"
        case "ipad": return "ipad"
        case "mac": return "desktopcomputer"
        case "appletv": return "appletv"
        default: return "questionmark.square"
        }
    }
    
    var statusColor: Color {
        switch device.enrollmentState?.uppercased() {
        case "ASSIGNED": return AppTheme.success
        case "UNASSIGNED": return AppTheme.warning
        default: return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 14) {
            // Device Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: deviceIcon)
                    .font(.title3)
                    .foregroundColor(.blue)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(device.model ?? device.serialNumber)
                    .font(.system(.body, weight: .medium))
                
                HStack(spacing: 12) {
                    if let productFamily = device.os {
                        Text(productFamily)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let productType = device.productType {
                        Text(productType)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Serial
            Text(device.serialNumber)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
            
            // Status Badge
            Text(device.enrollmentState ?? "Unknown")
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(statusColor.opacity(0.15))
                )
                .foregroundColor(statusColor)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

// MARK: - Device Detail Sheet
struct DeviceDetailSheet: View {
    let device: OrgDevice
    @ObservedObject var viewModel: ABMViewModel
    @Environment(\.dismiss) var dismiss
    @State private var assignedServer: String?
    @State private var appleCareCoverage: AppleCareCoverage?
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
                            DetailItem(label: "Device ID", value: device.id, monospaced: true)
                        }
                    }
                    .padding(16)
                    .materialCard(cornerRadius: 12, material: .ultraThinMaterial, strokeOpacity: 0.12, shadowOpacity: 0.04)
                    
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
                    .materialCard(cornerRadius: 12, material: .ultraThinMaterial, strokeOpacity: 0.12, shadowOpacity: 0.04)
                    
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
                        
                        if let coverage = appleCareCoverage {
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                CoverageItem(label: "Coverage Status", value: coverage.attributes.coverageStatus ?? "N/A", isActive: coverage.attributes.coverageStatus == "ACTIVE")
                                CoverageItem(label: "Warranty Status", value: coverage.attributes.warrantyStatus ?? "N/A", isActive: coverage.attributes.warrantyStatus == "ACTIVE")
                                DetailItem(label: "Coverage End Date", value: coverage.attributes.coverageEndDate ?? "N/A")
                                DetailItem(label: "Purchase Date", value: coverage.attributes.purchaseDate ?? "N/A")
                                DetailItem(label: "Repair Coverage", value: coverage.attributes.repairCoverage ?? "N/A")
                                DetailItem(label: "Tech Support", value: coverage.attributes.technicalSupportCoverage ?? "N/A")
                                DetailItem(label: "Plan Type", value: coverage.attributes.appleCarePlanType ?? "N/A")
                            }
                        } else if let error = appleCareError {
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(AppTheme.warning)
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(AppTheme.warning.opacity(0.12))
                            )
                        } else if !isLoadingAppleCare {
                            Button(action: loadAppleCare) {
                                Label("Check AppleCare Coverage", systemImage: "checkmark.shield")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(16)
                    .materialCard(cornerRadius: 12, material: .ultraThinMaterial, strokeOpacity: 0.12, shadowOpacity: 0.04)
                }
                .padding(20)
            }
        }
        .background(.ultraThinMaterial)
        .frame(width: 560, height: 580)
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
            let coverage = await viewModel.getAppleCareCoverage(deviceId: device.id)
            if let coverage = coverage {
                print("Got AppleCare coverage: \(coverage.attributes.coverageStatus ?? "nil")")
                appleCareCoverage = coverage
            } else {
                print("No AppleCare coverage returned")
                appleCareError = viewModel.errorMessage ?? "Unable to fetch coverage"
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
                    .fill(isActive ? AppTheme.success : AppTheme.warning)
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
            .background(.ultraThinMaterial)
            
            Divider()
            
            if viewModel.mdmServers.isEmpty {
                Spacer()
                ContentUnavailableView(
                    "No MDM Servers",
                    systemImage: "server.rack",
                    description: Text("Connect to \(viewModel.platform.displayName) to load your MDM servers")
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
                    .background(.thinMaterial)
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
    @State private var deviceSearchText = ""

    private var filteredDevices: [OrgDevice] {
        let query = deviceSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return viewModel.devices }

        return viewModel.devices.filter { device in
            device.serialNumber.localizedCaseInsensitiveContains(query) ||
            (device.model ?? "").localizedCaseInsensitiveContains(query)
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
            .background(.ultraThinMaterial)
            
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
                    .padding(16)
                    .materialCard(cornerRadius: 14, material: .regularMaterial, strokeOpacity: 0.12, shadowOpacity: 0.05)
                    
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
                        .padding(16)
                        .materialCard(cornerRadius: 14, material: .regularMaterial, strokeOpacity: 0.12, shadowOpacity: 0.05)
                    }
                    
                    // Device Selection
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Select Devices")
                                .font(.headline)
                            Spacer()
                            Text("\(selectedDevices.count) selected • \(filteredDevices.count) shown")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Search by serial or model...", text: $deviceSearchText)
                                .textFieldStyle(.plain)

                            if !deviceSearchText.isEmpty {
                                Button(action: { deviceSearchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .materialInsetField(cornerRadius: 8)
                        
                        if viewModel.devices.isEmpty {
                            Text("No devices available. Connect to \(viewModel.platform.displayName) first.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding()
                        } else if filteredDevices.isEmpty {
                            ContentUnavailableView.search(text: deviceSearchText)
                                .frame(height: 140)
                        } else {
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
                    .padding(16)
                    .materialCard(cornerRadius: 14, material: .regularMaterial, strokeOpacity: 0.12, shadowOpacity: 0.05)
                    
                    // Execute Button
                    Button(action: {
                        Task {
                            await viewModel.assignDevices(
                                deviceIds: Array(selectedDevices),
                                mdmId: actionType == "ASSIGN" ? selectedMDM : nil
                            )
                        }
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
                    
                    // Status Message
                    if let status = viewModel.statusMessage {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppTheme.success)
                            Text(status)
                                .font(.subheadline)
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(AppTheme.success.opacity(0.12))
                        )
                    }
                    
                    // Error Message
                    if let error = viewModel.errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(AppTheme.error)
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
                                .fill(AppTheme.error.opacity(0.12))
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
            .background(.ultraThinMaterial)
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Activity ID Input
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Check Activity")
                            .font(.headline)
                        
                        HStack(spacing: 12) {
                            TextField("Enter Activity ID...", text: $activityId)
                                .textFieldStyle(.plain)
                                .padding(8)
                                .materialInsetField(cornerRadius: 8)
                            
                            Button("Check Status") {
                                Task {
                                    await viewModel.checkActivityStatus(activityId: activityId)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(activityId.isEmpty)
                        }
                    }
                    .padding(16)
                    .materialCard(cornerRadius: 14, material: .regularMaterial, strokeOpacity: 0.12, shadowOpacity: 0.05)
                    
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
                            .materialCard(cornerRadius: 8, material: .ultraThinMaterial, strokeOpacity: 0.12, shadowOpacity: 0.03)
                        }
                        .padding(16)
                        .materialCard(cornerRadius: 14, material: .regularMaterial, strokeOpacity: 0.12, shadowOpacity: 0.05)
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
                            .materialCard(cornerRadius: 12, material: .ultraThinMaterial, strokeOpacity: 0.12, shadowOpacity: 0.04)
                        }
                        .padding(16)
                        .materialCard(cornerRadius: 14, material: .regularMaterial, strokeOpacity: 0.12, shadowOpacity: 0.05)
                    }
                }
                .padding(24)
                .padding(.bottom, 80) // Add bottom padding to scrollable content
            }
        }
    }
}


