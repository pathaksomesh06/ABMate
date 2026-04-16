//
//  AppsView.swift
//  ABMate
//
//  Apps & Packages management (ABM only).
//

import SwiftUI

// MARK: - Apps View
struct AppsView: View {
    @ObservedObject var viewModel: ABMViewModel
    @State private var searchText = ""
    @State private var showPackages = false
    @State private var selectedApp: ABMApp?
    @State private var showingDetail = false

    private var filteredApps: [ABMApp] {
        guard !searchText.isEmpty else { return viewModel.apps }
        return viewModel.apps.filter { app in
            (app.attributes.name ?? "").localizedCaseInsensitiveContains(searchText) ||
            (app.attributes.bundleId ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }

    private var filteredPackages: [ABMPackage] {
        guard !searchText.isEmpty else { return viewModel.packages }
        return viewModel.packages.filter { pkg in
            (pkg.attributes.name ?? "").localizedCaseInsensitiveContains(searchText) ||
            (pkg.attributes.bundleId ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Apps & Packages")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("\(viewModel.apps.count) apps • \(viewModel.packages.count) packages")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 12) {
                        // Search
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Search…", text: $searchText)
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
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(.ultraThinMaterial)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.white.opacity(0.14), lineWidth: 1)
                        )

                        Picker("View", selection: $showPackages) {
                            Text("Apps").tag(false)
                            Text("Packages").tag(true)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 160)

                        Button(action: {
                            viewModel.fetchApps()
                            viewModel.fetchPackages()
                        }) {
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
            if showPackages {
                packagesList
            } else {
                appsList
            }

            // Status Bar
            HStack {
                if showPackages {
                    Text("\(filteredPackages.count) of \(viewModel.packages.count) packages")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("\(filteredApps.count) of \(viewModel.apps.count) apps")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if !searchText.isEmpty {
                    Button("Clear Search") { searchText = "" }
                        .font(.caption)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.thinMaterial)
        }
        .sheet(isPresented: $showingDetail) {
            if let app = selectedApp {
                AppDetailSheet(app: app)
            }
        }
    }

    // MARK: - Apps List

    @ViewBuilder
    private var appsList: some View {
        if viewModel.apps.isEmpty {
            Spacer()
            ContentUnavailableView(
                "No Apps",
                systemImage: "app.badge",
                description: Text("Connect to \(viewModel.platform.displayName) to load apps")
            )
            Spacer()
        } else if filteredApps.isEmpty {
            Spacer()
            ContentUnavailableView.search(text: searchText)
            Spacer()
        } else {
            List(filteredApps) { app in
                AppRow(app: app)
                    .onTapGesture(count: 2) {
                        selectedApp = app
                        showingDetail = true
                    }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
        }
    }

    // MARK: - Packages List

    @ViewBuilder
    private var packagesList: some View {
        if viewModel.packages.isEmpty {
            Spacer()
            ContentUnavailableView(
                "No Packages",
                systemImage: "shippingbox",
                description: Text("No packages found")
            )
            Spacer()
        } else if filteredPackages.isEmpty {
            Spacer()
            ContentUnavailableView.search(text: searchText)
            Spacer()
        } else {
            List(filteredPackages) { pkg in
                PackageRow(package: pkg)
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
        }
    }
}

// MARK: - App Row
struct AppRow: View {
    let app: ABMApp

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: app.attributes.isCustomApp == true ? "app.gift" : "app")
                    .font(.title3)
                    .foregroundColor(.green)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(app.attributes.name ?? app.id)
                    .font(.system(.body, weight: .medium))

                if let artistName = app.attributes.artistName {
                    Text(artistName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if let bundleId = app.attributes.bundleId {
                    Text(bundleId)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if let price = app.attributes.priceFormatted {
                Text(price)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let total = app.attributes.totalCount {
                Text("\(app.attributes.assignedCount ?? 0)/\(total)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.purple.opacity(0.1)))
                    .foregroundColor(.purple)
                    .help("Assigned / Total licenses")
            }

            if let os = app.attributes.deviceFamilies ?? app.attributes.supportedOS, !os.isEmpty {
                Text(os.joined(separator: ", "))
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.blue.opacity(0.1)))
                    .foregroundColor(.blue)
            }

            if app.attributes.isCustomApp == true {
                Text("Custom")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.orange.opacity(0.15)))
                    .foregroundColor(.orange)
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

// MARK: - Package Row
struct PackageRow: View {
    let package: ABMPackage

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.indigo.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: "shippingbox")
                    .font(.title3)
                    .foregroundColor(.indigo)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(package.attributes.name ?? package.id)
                    .font(.system(.body, weight: .medium))

                if let bundleId = package.attributes.bundleId {
                    Text(bundleId)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if let version = package.attributes.version {
                Text("v\(version)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let os = package.attributes.supportedOS, !os.isEmpty {
                Text(os.joined(separator: ", "))
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.indigo.opacity(0.1)))
                    .foregroundColor(.indigo)
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

// MARK: - App Detail Sheet
struct AppDetailSheet: View {
    let app: ABMApp
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(app.attributes.name ?? "App")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("App Details")
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
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        DetailItem(label: "Name", value: app.attributes.name ?? "N/A")
                        DetailItem(label: "Developer", value: app.attributes.artistName ?? "N/A")
                        DetailItem(label: "Bundle ID", value: app.attributes.bundleId ?? "N/A", monospaced: true)
                        DetailItem(label: "Version", value: app.attributes.version ?? "N/A")
                        DetailItem(label: "Custom App", value: app.attributes.isCustomApp == true ? "Yes" : "No")
                        DetailItem(label: "Price", value: app.attributes.priceFormatted ?? "N/A")
                        DetailItem(label: "Platforms", value: app.attributes.deviceFamilies?.joined(separator: ", ") ?? app.attributes.supportedOS?.joined(separator: ", ") ?? "N/A")
                        DetailItem(label: "App ID", value: app.id, monospaced: true)
                        if app.attributes.totalCount != nil {
                            DetailItem(label: "Total Licenses", value: "\(app.attributes.totalCount ?? 0)")
                            DetailItem(label: "Assigned", value: "\(app.attributes.assignedCount ?? 0)")
                            DetailItem(label: "Available", value: "\(app.attributes.availableCount ?? 0)")
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )

                    if let url = app.attributes.appStoreUrl {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("App Store URL")
                                .font(.headline)
                            Text(url)
                                .font(.caption)
                                .foregroundColor(.blue)
                                .textSelection(.enabled)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.ultraThinMaterial)
                        )
                    }

                    if let url = app.attributes.websiteUrl {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Website")
                                .font(.headline)
                            Text(url)
                                .font(.caption)
                                .foregroundColor(.blue)
                                .textSelection(.enabled)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.ultraThinMaterial)
                        )
                    }
                }
                .padding(20)
            }
        }
        .background(.ultraThinMaterial)
        .frame(width: 520, height: 420)
    }
}
