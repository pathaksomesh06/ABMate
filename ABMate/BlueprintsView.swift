//
//  BlueprintsView.swift
//  ABMate
//
//  Blueprints CRUD management (ABM only).
//

import SwiftUI

// MARK: - Blueprints View
struct BlueprintsView: View {
    @ObservedObject var viewModel: ABMViewModel
    @State private var searchText = ""

    private var filteredBlueprints: [Blueprint] {
        guard !searchText.isEmpty else { return viewModel.blueprints }
        return viewModel.blueprints.filter { bp in
            (bp.attributes.name ?? "").localizedCaseInsensitiveContains(searchText) ||
            bp.id.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Blueprints")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("\(viewModel.blueprints.count) blueprints")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 12) {
                        // Search
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Search blueprints…", text: $searchText)
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

                        Button(action: { viewModel.fetchBlueprints() }) {
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
            if viewModel.blueprints.isEmpty {
                Spacer()
                ContentUnavailableView(
                    "No Blueprints",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("Connect to \(viewModel.platform.displayName) to view blueprints")
                )
                Spacer()
            } else if filteredBlueprints.isEmpty {
                Spacer()
                ContentUnavailableView.search(text: searchText)
                Spacer()
            } else {
                List(filteredBlueprints) { bp in
                    BlueprintRow(blueprint: bp)
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }

            // Status Bar
            HStack {
                Text("\(filteredBlueprints.count) of \(viewModel.blueprints.count) blueprints")
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

// MARK: - Blueprint Row
struct BlueprintRow: View {
    let blueprint: Blueprint

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.teal.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.title3)
                    .foregroundColor(.teal)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(blueprint.attributes.name ?? blueprint.id)
                    .font(.system(.body, weight: .medium))

                HStack(spacing: 12) {
                    if let created = blueprint.attributes.createdDateTime {
                        Text("Created: \(created)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let updated = blueprint.attributes.updatedDateTime {
                        Text("Updated: \(updated)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            Text(blueprint.id)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}
