//
//  KeychainHelper.swift
//  ABMate
//
//  Secure storage helper for private keys using macOS Keychain Services.
//

import Foundation
import Security

enum KeychainHelper {

    /// Save a string value to the Keychain for a given account identifier.
    @discardableResult
    static func save(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        // Delete any existing item first to avoid duplicates
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.abmate.connectionProfiles",
            kSecAttrAccount as String: key
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Add the new item
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.abmate.connectionProfiles",
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        return status == errSecSuccess
    }

    /// Read a string value from the Keychain for a given account identifier.
    static func read(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.abmate.connectionProfiles",
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    /// Delete a value from the Keychain for a given account identifier.
    @discardableResult
    static func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.abmate.connectionProfiles",
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    // MARK: - Profile-specific convenience methods

    /// Save a private key for a connection profile UUID.
    @discardableResult
    static func savePrivateKey(_ privateKey: String, forProfileId id: UUID) -> Bool {
        save(key: "profile-privateKey-\(id.uuidString)", value: privateKey)
    }

    /// Read the private key for a connection profile UUID.
    static func readPrivateKey(forProfileId id: UUID) -> String? {
        read(key: "profile-privateKey-\(id.uuidString)")
    }

    /// Delete the private key for a connection profile UUID.
    @discardableResult
    static func deletePrivateKey(forProfileId id: UUID) -> Bool {
        delete(key: "profile-privateKey-\(id.uuidString)")
    }
}
