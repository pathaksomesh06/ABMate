//
//  AuditEventsView.swift
//  ABMate
//
//  Audit Events viewer with date filtering (ABM only).
//

import SwiftUI

// MARK: - Audit Events View
struct AuditEventsView: View {
    @ObservedObject var viewModel: ABMViewModel
    @State private var searchText = ""
    @State private var startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    @State private var endDate = Date()
    @State private var filterCategory = "All"
    @State private var selectedEvent: AuditEvent?
    @State private var showingDetail = false

    private var categories: [String] {
        var cats = Set(viewModel.auditEvents.compactMap { $0.attributes.category })
        cats.insert("All")
        return ["All"] + cats.sorted().filter { $0 != "All" }
    }

    private var filteredEvents: [AuditEvent] {
        var events = viewModel.auditEvents

        if filterCategory != "All" {
            events = events.filter { $0.attributes.category == filterCategory }
        }

        if !searchText.isEmpty {
            events = events.filter { event in
                (event.attributes.eventType ?? "").localizedCaseInsensitiveContains(searchText) ||
                (event.attributes.actorName ?? "").localizedCaseInsensitiveContains(searchText) ||
                (event.attributes.subjectName ?? "").localizedCaseInsensitiveContains(searchText) ||
                (event.attributes.category ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }

        return events
    }

    private static let dateFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Audit Events")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("\(viewModel.auditEvents.count) events loaded")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 12) {
                        // Search
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Search events…", text: $searchText)
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
                        .frame(width: 200)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(.ultraThinMaterial)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.white.opacity(0.14), lineWidth: 1)
                        )

                        Button(action: fetchWithDateRange) {
                            Label("Fetch Events", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

                // Date Range Filters
                HStack(spacing: 16) {
                    HStack(spacing: 8) {
                        Text("From:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        DatePicker("", selection: $startDate, displayedComponents: [.date])
                            .labelsHidden()
                    }

                    HStack(spacing: 8) {
                        Text("To:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        DatePicker("", selection: $endDate, displayedComponents: [.date])
                            .labelsHidden()
                    }

                    if categories.count > 1 {
                        Picker("Category", selection: $filterCategory) {
                            ForEach(categories, id: \.self) { cat in
                                Text(cat).tag(cat)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 160)
                    }

                    Spacer()
                }
            }
            .padding(20)
            .background(.ultraThinMaterial)

            Divider()

            // Content
            if viewModel.auditEvents.isEmpty {
                Spacer()
                ContentUnavailableView(
                    "No Audit Events",
                    systemImage: "list.bullet.clipboard",
                    description: Text("Fetch audit events using the date range above")
                )
                Spacer()
            } else if filteredEvents.isEmpty {
                Spacer()
                ContentUnavailableView.search(text: searchText.isEmpty ? filterCategory : searchText)
                Spacer()
            } else {
                List(filteredEvents) { event in
                    AuditEventRow(event: event)
                        .onTapGesture(count: 2) {
                            selectedEvent = event
                            showingDetail = true
                        }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }

            // Status Bar
            HStack {
                Text("\(filteredEvents.count) of \(viewModel.auditEvents.count) events")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if filterCategory != "All" || !searchText.isEmpty {
                    Button("Clear Filters") {
                        filterCategory = "All"
                        searchText = ""
                    }
                    .font(.caption)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.thinMaterial)
        }
        .sheet(isPresented: $showingDetail) {
            if let event = selectedEvent {
                AuditEventDetailSheet(event: event)
            }
        }
    }

    private func fetchWithDateRange() {
        let start = Self.dateFormatter.string(from: startDate)
        let end = Self.dateFormatter.string(from: endDate)
        viewModel.fetchAuditEvents(startDateTime: start, endDateTime: end)
    }
}

// MARK: - Audit Event Row
struct AuditEventRow: View {
    let event: AuditEvent

    private var outcomeColor: Color {
        switch event.attributes.outcome?.uppercased() {
        case "SUCCESS": return .green
        case "FAILURE": return .red
        default: return .gray
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(outcomeColor.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: event.attributes.outcome?.uppercased() == "SUCCESS" ? "checkmark.circle" : "exclamationmark.triangle")
                    .font(.title3)
                    .foregroundColor(outcomeColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(event.attributes.eventType ?? "Unknown Event")
                    .font(.system(.body, weight: .medium))

                HStack(spacing: 12) {
                    if let category = event.attributes.category {
                        Text(category)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let actor = event.attributes.actorName {
                        Text("by \(actor)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            if let dateTime = event.attributes.eventDateTime {
                Text(dateTime)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Text(event.attributes.outcome ?? "Unknown")
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(outcomeColor.opacity(0.15)))
                .foregroundColor(outcomeColor)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

// MARK: - Audit Event Detail Sheet
struct AuditEventDetailSheet: View {
    let event: AuditEvent
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.attributes.eventType ?? "Audit Event")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Event Details")
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
                    // Event Info
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Event Information")
                            .font(.headline)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            DetailItem(label: "Event Type", value: event.attributes.eventType ?? "N/A")
                            DetailItem(label: "Category", value: event.attributes.category ?? "N/A")
                            DetailItem(label: "Date/Time", value: event.attributes.eventDateTime ?? "N/A")
                            DetailItem(label: "Outcome", value: event.attributes.outcome ?? "N/A")
                            DetailItem(label: "Event ID", value: event.id, monospaced: true)
                            DetailItem(label: "Group ID", value: event.attributes.groupId ?? "N/A", monospaced: true)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )

                    // Actor Info
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Actor")
                            .font(.headline)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            DetailItem(label: "Actor Name", value: event.attributes.actorName ?? "N/A")
                            DetailItem(label: "Actor Type", value: event.attributes.actorType ?? "N/A")
                            DetailItem(label: "Actor ID", value: event.attributes.actorId ?? "N/A", monospaced: true)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )

                    // Subject Info
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Subject")
                            .font(.headline)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            DetailItem(label: "Subject Name", value: event.attributes.subjectName ?? "N/A")
                            DetailItem(label: "Subject Type", value: event.attributes.subjectType ?? "N/A")
                            DetailItem(label: "Subject ID", value: event.attributes.subjectId ?? "N/A", monospaced: true)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
                }
                .padding(20)
            }
        }
        .background(.ultraThinMaterial)
        .frame(width: 560, height: 520)
    }
}
