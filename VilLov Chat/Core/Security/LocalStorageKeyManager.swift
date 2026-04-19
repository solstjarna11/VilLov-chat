//
//  LocalStorageKeyManager.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 19.4.2026.
//


import Foundation
import CryptoKit
import Security

enum LocalStorageKeyManagerError: Error {
    case keychainStoreFailed(OSStatus)
    case keychainLoadFailed(OSStatus)
    case invalidStoredKey
}

final class LocalStorageKeyManager {
    private let service = "com.villovchat.local-storage"
    private let account = "master-key"

    func loadOrCreateMasterKey() throws -> SymmetricKey {
        if let existing = try loadKeyData() {
            guard existing.count == 32 else {
                throw LocalStorageKeyManagerError.invalidStoredKey
            }
            return SymmetricKey(data: existing)
        }

        let newKey = SymmetricKey(size: .bits256)
        let raw = newKey.withUnsafeBytes { Data($0) }
        try saveKeyData(raw)
        return newKey
    }

    private func saveKeyData(_ data: Data) throws {
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw LocalStorageKeyManagerError.keychainStoreFailed(status)
        }
    }

    private func loadKeyData() throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let data = result as? Data else {
                throw LocalStorageKeyManagerError.invalidStoredKey
            }
            return data
        case errSecItemNotFound:
            return nil
        default:
            throw LocalStorageKeyManagerError.keychainLoadFailed(status)
        }
    }
}
