//
//  UsersView.swift
//  ABMate
//
//  Users & User Groups management (ABM only).
//

import SwiftUI

// MARK: - Users View
struct UsersView: View {
    @ObservedObject var viewModel: ABMViewModel
    @State private var searchText = ""
    @State private var selectedUser: ABMUser?
    @State private var showingDetail = false
    @State private var showGroups = false

    private var filteredUsers: [ABMUser] {
        guard !searchText.isEmpty else { return viewModel.users }
        return viewModel.users.filter { user in
            user.displayName.localizedCaseInsensitiveContains(searchText) ||
            (user.attributes.email ?? "").localizedCaseInsensitiveContains(searchText) ||
            (user.attributes.managedAppleId ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Users")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("\(viewModel.users.count) users • \(viewModel.userGroups.count) groups")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 12) {
                        // Search
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Search users…", text: $searchText)
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

                        Picker("View", selection: $showGroups) {
                            Text("Users").tag(false)
                            Text("Groups").tag(true)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 160)

                        Button(action: {
                            viewModel.fetchUsers()
                            viewModel.fetchUserGroups()
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
            if showGroups {
                userGroupsList
            } else {
                usersList
            }

            // Status Bar
            HStack {
                if showGroups {
                    Text("\(viewModel.userGroups.count) groups")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("\(filteredUsers.count) of \(viewModel.users.count) users")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.thinMaterial)
        }
        .sheet(isPresented: $showingDetail) {
            if let user = selectedUser {
                UserDetailSheet(user: user)
            }
        }
    }

    // MARK: - Users List

    @ViewBuilder
    private var usersList: some View {
        if viewModel.users.isEmpty {
            Spacer()
            ContentUnavailableView(
                "No Users",
                systemImage: "person.2",
                description: Text("Connect to \(viewModel.platform.displayName) to load users")
            )
            Spacer()
        } else if filteredUsers.isEmpty {
            Spacer()
            ContentUnavailableView.search(text: searchText)
            Spacer()
        } else {
            List(filteredUsers, selection: $selectedUser) { user in
                UserRow(user: user)
                    .onTapGesture(count: 2) {
                        selectedUser = user
                        showingDetail = true
                    }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
        }
    }

    // MARK: - User Groups List

    @ViewBuilder
    private var userGroupsList: some View {
        if viewModel.userGroups.isEmpty {
            Spacer()
            ContentUnavailableView(
                "No User Groups",
                systemImage: "person.3",
                description: Text("No user groups found")
            )
            Spacer()
        } else {
            List(viewModel.userGroups) { group in
                UserGroupRow(group: group)
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
        }
    }
}

// MARK: - User Row
struct UserRow: View {
    let user: ABMUser

    private var statusColor: Color {
        switch user.attributes.status?.uppercased() {
        case "ACTIVE": return .green
        case "SUSPENDED": return .orange
        case "INACTIVE": return .gray
        default: return .gray
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: "person.fill")
                    .font(.title3)
                    .foregroundColor(.orange)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(user.displayName)
                    .font(.system(.body, weight: .medium))

                if let email = user.attributes.email {
                    Text(email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if let appleId = user.attributes.managedAppleId {
                Text(appleId)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            if let roles = user.attributes.roles, let firstRole = roles.first?.role {
                Text(firstRole)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.blue.opacity(0.12)))
                    .foregroundColor(.blue)
            }

            Text(user.attributes.status ?? "Unknown")
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(statusColor.opacity(0.15)))
                .foregroundColor(statusColor)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

// MARK: - User Group Row
struct UserGroupRow: View {
    let group: ABMUserGroup

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.purple.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: "person.3.fill")
                    .font(.title3)
                    .foregroundColor(.purple)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(group.attributes.name ?? group.id)
                    .font(.system(.body, weight: .medium))

                if let groupType = group.attributes.groupType {
                    Text(groupType)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if let status = group.attributes.status {
                Text(status)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.purple.opacity(0.12)))
                    .foregroundColor(.purple)
            }

            Text(group.id)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

// MARK: - User Detail Sheet
struct UserDetailSheet: View {
    let user: ABMUser
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.displayName)
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("User Details")
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
                        DetailItem(label: "First Name", value: user.attributes.firstName ?? "N/A")
                        DetailItem(label: "Last Name", value: user.attributes.lastName ?? "N/A")
                        DetailItem(label: "Email", value: user.attributes.email ?? "N/A")
                        DetailItem(label: "Managed Apple ID", value: user.attributes.managedAppleId ?? "N/A")
                        DetailItem(label: "Status", value: user.attributes.status ?? "N/A")
                        DetailItem(label: "User ID", value: user.id, monospaced: true)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )

                    // Roles
                    if let roles = user.attributes.roles, !roles.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Roles")
                                .font(.headline)

                            ForEach(Array(roles.enumerated()), id: \.offset) { _, role in
                                HStack {
                                    Image(systemName: "person.badge.shield.checkmark")
                                        .foregroundColor(.blue)
                                    Text(role.role ?? "Unknown role")
                                        .font(.body)
                                    if let ou = role.organizationalUnit {
                                        Text("(\(ou))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color.blue.opacity(0.06)))
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.ultraThinMaterial)
                        )
                    }

                    // Phone Numbers
                    if let phones = user.attributes.phoneNumbers, !phones.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Phone Numbers")
                                .font(.headline)

                            ForEach(Array(phones.enumerated()), id: \.offset) { _, phone in
                                HStack {
                                    Image(systemName: "phone")
                                        .foregroundColor(.green)
                                    Text(phone.number ?? "N/A")
                                    if let type = phone.type {
                                        Text("(\(type))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
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
        .frame(width: 520, height: 480)
    }
}
