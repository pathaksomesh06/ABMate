//
//  ConfigurationsView.swift
//  ABMate
//
//  Configurations CRUD management (ABM only).
//

import SwiftUI

// MARK: - Configurations View
struct ConfigurationsView: View {
    @ObservedObject var viewModel: ABMViewModel
    @State private var searchText = ""

    private var filteredConfigurations: [ABMConfiguration] {
        guard !searchText.isEmpty else { return viewModel.configurations }
        return viewModel.configurations.filter { config in
            (config.attributes.name ?? "").localizedCaseInsensitiveContains(searchText) ||
            (config.attributes.configurationType ?? "").localizedCaseInsensitiveContains(searchText) ||
            config.id.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Configurations")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("\(viewModel.configurations.count) configurations")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 12) {
                        // Search
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Search configurations…", text: $searchText)
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
                        .frame(width: 240)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(.ultraThinMaterial)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.white.opacity(0.14), lineWidth: 1)
                        )

                        Button(action: { viewModel.fetchConfigurations() }) {
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
            if viewModel.configurations.isEmpty {
                Spacer()
                ContentUnavailableView(
                    "No Configurations",
                    systemImage: "gearshape.2",
                    description: Text("Connect to \(viewModel.platform.displayName) to view configurations")
                )
                Spacer()
            } else if filteredConfigurations.isEmpty {
                Spacer()
                ContentUnavailableView.search(text: searchText)
                Spacer()
            } else {
                List(filteredConfigurations) { config in
                    ConfigurationRow(configuration: config)
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }

            // Status Bar
            HStack {
                Text("\(filteredConfigurations.count) of \(viewModel.configurations.count) configurations")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.thinMaterial)
        }
    }
}

// MARK: - Configuration Row
struct ConfigurationRow: View {
    let configuration: ABMConfiguration

    private var typeColor: Color {
        switch configuration.attributes.configurationType?.uppercased() {
        case "CUSTOM_SETTING": return .indigo
        default: return .gray
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.indigo.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: "gearshape.2")
                    .font(.title3)
                    .foregroundColor(.indigo)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(configuration.attributes.name ?? configuration.id)
                    .font(.system(.body, weight: .medium))

                HStack(spacing: 12) {
                    if let configType = configuration.attributes.configurationType {
                        Text(configType)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let created = configuration.attributes.createdDateTime {
                        Text("Created: \(created)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            if let configType = configuration.attributes.configurationType {
                Text(configType)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(typeColor.opacity(0.12)))
                    .foregroundColor(typeColor)
            }

            Text(configuration.id)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}
