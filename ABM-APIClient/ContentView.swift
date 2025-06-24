//
//  ContentView.swift
//  ABM-APIClient
//
//  © Created by Somesh Pathak on 23/06/2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var viewModel = ABMViewModel()
    @State private var showingPrivateKeyInput = false
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationSplitView {
            // Sidebar - Credentials
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "network")
                            .font(.largeTitle)
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text("ABM API Client")
                                .font(.headline)
                            Text("Manage your devices")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.bottom, 8)
                    
                    Divider()
                }
                .padding()
                
                // Credentials Form
                VStack(alignment: .leading, spacing: 20) {
                    Label("API Credentials", systemImage: "key.fill")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Client ID", systemImage: "person.circle")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("BUSINESSAPI.xxx", text: $viewModel.clientId)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Key ID", systemImage: "key")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("d136aa66-xxx", text: $viewModel.keyId)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Private Key", systemImage: "lock.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Button(action: { showingPrivateKeyInput = true }) {
                                HStack {
                                    Image(systemName: viewModel.privateKey.isEmpty ? "doc.badge.plus" : "checkmark.circle.fill")
                                        .foregroundColor(viewModel.privateKey.isEmpty ? .secondary : .green)
                                    Text(viewModel.privateKey.isEmpty ? "Load Private Key File" : "Private Key Loaded")
                                    Spacer()
                                }
                                .padding(8)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    Divider()
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: { viewModel.generateJWT() }) {
                            HStack {
                                Image(systemName: "lock.rotation")
                                Text("Generate JWT")
                                Spacer()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(viewModel.clientId.isEmpty || viewModel.keyId.isEmpty || viewModel.privateKey.isEmpty)
                        
                        Button(action: {
                            viewModel.fetchDevices()
                            viewModel.fetchMDMServers()
                        }) {
                            HStack {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                Text("Connect to ABM")
                                Spacer()
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .disabled(viewModel.clientAssertion == nil)
                    }
                    
                    // Status Section
                    if viewModel.isLoading || viewModel.statusMessage != nil || viewModel.errorMessage != nil {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            if viewModel.isLoading {
                                HStack {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .scaleEffect(0.8)
                                    Text("Loading...")
                                        .font(.caption)
                                }
                            }
                            
                            if let status = viewModel.statusMessage {
                                HStack {
                                    Image(systemName: "checkmark.circle")
                                        .foregroundColor(.green)
                                    Text(status)
                                        .font(.caption)
                                }
                            }
                            
                            if let error = viewModel.errorMessage {
                                HStack(alignment: .top) {
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundColor(.red)
                                    Text(error)
                                        .font(.caption)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .padding(12)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(8)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .frame(minWidth: 320, idealWidth: 350)
            .background(Color(NSColor.controlBackgroundColor))
        } detail: {
            // Main content with tabs
            TabView(selection: $selectedTab) {
                // Devices Tab
                DevicesView(viewModel: viewModel)
                    .tabItem {
                        Label("Devices", systemImage: "desktopcomputer")
                    }
                    .tag(0)
                
                // MDM Servers Tab
                MDMServersView(viewModel: viewModel)
                    .tabItem {
                        Label("MDM Servers", systemImage: "server.rack")
                    }
                    .tag(1)
                
                // Device Assignment Tab
                DeviceAssignmentView(viewModel: viewModel)
                    .tabItem {
                        Label("Assign Devices", systemImage: "arrow.right.square")
                    }
                    .tag(2)
                
                // Activity Status Tab
                ActivityStatusView(viewModel: viewModel)
                    .tabItem {
                        Label("Activity Status", systemImage: "clock.arrow.circlepath")
                    }
                    .tag(3)
            }
            .frame(minWidth: 800, maxWidth: .infinity, minHeight: 600, maxHeight: .infinity)
        }
        .onAppear {
            viewModel.loadCredentials()
        }
        .fileImporter(
            isPresented: $showingPrivateKeyInput,
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

// Devices View
struct DevicesView: View {
    @ObservedObject var viewModel: ABMViewModel
    @State private var selectedDevice: OrgDevice?
    @State private var showingDetails = false
    @State private var searchText = ""
    @State private var showingExporter = false
    
    var filteredDevices: [OrgDevice] {
        if searchText.isEmpty {
            return viewModel.devices
        } else {
            return viewModel.devices.filter { device in
                device.serialNumber.localizedCaseInsensitiveContains(searchText) ||
                (device.name ?? "").localizedCaseInsensitiveContains(searchText) ||
                (device.model ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 16) {
                Text("Devices")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search devices...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .frame(maxWidth: 300)
                
                // Action buttons
                HStack(spacing: 12) {
                    Button(action: { showingExporter = true }) {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.devices.isEmpty)
                    
                    Button(action: { viewModel.fetchDevices() }) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Device list
            if viewModel.devices.isEmpty {
                Spacer()
                ContentUnavailableView(
                    "No Devices",
                    systemImage: "laptopcomputer",
                    description: Text("Click 'Connect to ABM' in the sidebar to load devices")
                )
                Spacer()
            } else if filteredDevices.isEmpty {
                Spacer()
                ContentUnavailableView.search(text: searchText)
                Spacer()
            } else {
                List(filteredDevices, selection: $selectedDevice) { device in
                    DeviceRow(device: device)
                        .onTapGesture {
                            selectedDevice = device
                            showingDetails = true
                        }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
                
                // Status bar
                HStack {
                    Text("\(filteredDevices.count) devices")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor))
            }
        }
        .sheet(isPresented: $showingDetails) {
            if let device = selectedDevice {
                DeviceDetailView(device: device, viewModel: viewModel)
            }
        }
        .fileExporter(
            isPresented: $showingExporter,
            document: CSVDocument(devices: filteredDevices),
            contentType: .commaSeparatedText,
            defaultFilename: "devices_\(Date().formatted(date: .abbreviated, time: .omitted)).csv"
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

// Device Row
struct DeviceRow: View {
    let device: OrgDevice
    
    var deviceIcon: String {
        switch device.os?.lowercased() {
        case "ios": return "iphone"
        case "ipados": return "ipad"
        case "macos": return "desktopcomputer"
        case "tvos": return "appletv"
        default: return "questionmark.square"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: deviceIcon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(device.name ?? device.serialNumber)
                    .font(.system(.body, weight: .medium))
                
                HStack(spacing: 8) {
                    if let model = device.model {
                        Label(model, systemImage: "info.circle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let os = device.os, let version = device.osVersion {
                        Label("\(os) \(version)", systemImage: "gear")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Text(device.enrollmentState ?? "Unknown")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(device.enrollmentState == "ASSIGNED" ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                .cornerRadius(4)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

// Device Detail View
struct DeviceDetailView: View {
    let device: OrgDevice
    @ObservedObject var viewModel: ABMViewModel
    @State private var deviceDetails: OrgDevice?
    @State private var assignedServer: String?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Device Information") {
                    LabeledContent("Serial Number", value: device.serialNumber)
                    LabeledContent("Name", value: device.name ?? "N/A")
                    LabeledContent("Model", value: device.model ?? "N/A")
                    LabeledContent("OS", value: "\(device.os ?? "N/A") \(device.osVersion ?? "")")
                    LabeledContent("Status", value: device.enrollmentState ?? "N/A")
                    LabeledContent("ID", value: device.id)
                }
                
                Section("Actions") {
                    Button("Get Assigned Server") {
                        Task {
                            await viewModel.getDeviceAssignedServer(deviceId: device.id)
                        }
                    }
                    
                    if let server = assignedServer {
                        LabeledContent("Assigned Server", value: server)
                    }
                }
            }
            .navigationTitle("Device Details")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
    }
}

// MDM Servers View
struct MDMServersView: View {
    @ObservedObject var viewModel: ABMViewModel
    @State private var selectedServer: MDMServer?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                HStack {
                    Text("MDM Servers")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top)
                
                Divider()
            }
            
            // Content
            if viewModel.mdmServers.isEmpty {
                ContentUnavailableView(
                    "No MDM Servers",
                    systemImage: "server.rack",
                    description: Text("Click 'Connect to ABM' in the sidebar to load servers")
                )
            } else {
                List(viewModel.mdmServers, selection: $selectedServer) { server in
                    VStack(alignment: .leading) {
                        Text(server.attributes.serverName)
                            .font(.headline)
                        Text(server.attributes.serverType)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("ID: \(server.id)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
                
                if let server = selectedServer {
                    VStack(alignment: .leading, spacing: 12) {
                        Divider()
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
                        .padding()
                    }
                    .background(Color(NSColor.controlBackgroundColor))
                }
            }
        }
    }
}

// Device Assignment View
struct DeviceAssignmentView: View {
    @ObservedObject var viewModel: ABMViewModel
    @State private var selectedDevices: Set<String> = []
    @State private var selectedMDM: String = ""
    @State private var actionType = "ASSIGN"
    
    var body: some View {
        VStack {
            Text("Device Assignment")
                .font(.largeTitle)
                .padding()
            
            Form {
                Section("Select Action") {
                    Picker("Action", selection: $actionType) {
                        Text("Assign").tag("ASSIGN")
                        Text("Unassign").tag("UNASSIGN")
                    }
                    .pickerStyle(.segmented)
                }
                
                if actionType == "ASSIGN" {
                    Section("Select MDM Server") {
                        Picker("MDM Server", selection: $selectedMDM) {
                            Text("Select Server").tag("")
                            ForEach(viewModel.mdmServers) { server in
                                Text(server.attributes.serverName).tag(server.id)
                            }
                        }
                    }
                }
                
                Section("Select Devices") {
                    List(viewModel.devices, selection: $selectedDevices) { device in
                        HStack {
                            Text(device.name ?? device.serialNumber)
                            Spacer()
                            if selectedDevices.contains(device.id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .frame(minHeight: 200)
                }
                
                Button("Execute") {
                    Task {
                        await viewModel.assignDevices(
                            deviceIds: Array(selectedDevices),
                            mdmId: actionType == "ASSIGN" ? selectedMDM : nil
                        )
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedDevices.isEmpty || (actionType == "ASSIGN" && selectedMDM.isEmpty))
            }
        }
    }
}

// Activity Status View
struct ActivityStatusView: View {
    @ObservedObject var viewModel: ABMViewModel
    @State private var activityId = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                HStack {
                    Text("Activity Status")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top)
                
                Divider()
            }
            
            // Content
            VStack(spacing: 24) {
                Form {
                    Section("Check Activity Status") {
                        HStack {
                            TextField("Activity ID", text: $activityId)
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
                    
                    if let status = viewModel.activityStatus {
                        Section("Status") {
                            HStack {
                                Text("ID")
                                    .fontWeight(.medium)
                                    .frame(width: 100, alignment: .leading)
                                Text(status.data.id)
                                    .textSelection(.enabled)
                                    .font(.system(.body, design: .monospaced))
                                Spacer()
                                Button(action: {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(status.data.id, forType: .string)
                                }) {
                                    Image(systemName: "doc.on.doc")
                                        .foregroundColor(.blue)
                                }
                                .buttonStyle(.plain)
                                .help("Copy Activity ID")
                            }
                            
                            LabeledContent("Status", value: status.data.attributes.status)
                            LabeledContent("Sub-Status", value: status.data.attributes.subStatus)
                            LabeledContent("Created", value: status.data.attributes.createdDateTime)
                        }
                    }
                    
                    if let lastId = viewModel.lastActivityId {
                        Section("Recent Activity") {
                            HStack {
                                Text("Last Activity ID")
                                    .fontWeight(.medium)
                                Spacer()
                                Text(lastId)
                                    .textSelection(.enabled)
                                    .font(.system(.body, design: .monospaced))
                                    .lineLimit(1)
                                Button(action: {
                                    activityId = lastId
                                    Task {
                                        await viewModel.checkActivityStatus(activityId: lastId)
                                    }
                                }) {
                                    Image(systemName: "arrow.clockwise")
                                        .foregroundColor(.blue)
                                }
                                .buttonStyle(.plain)
                                .help("Check this activity")
                            }
                        }
                    }
                }
                .formStyle(.grouped)
                .frame(maxWidth: 800)
                
                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
