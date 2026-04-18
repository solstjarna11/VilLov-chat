//
//  DevPasskeyCredentialStore.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 17.4.2026.
//


import Foundation
import CryptoKit
import Security

enum DevPasskeyStoreError: Error {
    case keychain(OSStatus)
    case corruptCredential
    case encodingFailed
}

struct DevPasskeyCredentialRecord: Codable, Equatable {
    let userHandle: String
    let credentialID: String
    let privateKeyRawRepresentation: Data
    let publicKeyRawRepresentation: Data
    let signCount: UInt32
}

final class DevPasskeyCredentialStore {
    private let service = "com.villovchat.devpasskeys"

    func loadCredential(for userHandle: String) throws -> DevPasskeyCredentialRecord? {
        guard let data = try readData(account: accountKey(for: userHandle)) else {
            return nil
        }

        do {
            return try JSONDecoder().decode(DevPasskeyCredentialRecord.self, from: data)
        } catch {
            throw DevPasskeyStoreError.corruptCredential
        }
    }

    func saveCredential(_ credential: DevPasskeyCredentialRecord) throws {
        let data: Data
        do {
            data = try JSONEncoder().encode(credential)
        } catch {
            throw DevPasskeyStoreError.encodingFailed
        }

        try writeData(data, account: accountKey(for: credential.userHandle))
    }

    func updateSignCount(for userHandle: String, signCount: UInt32) throws {
        guard var credential = try loadCredential(for: userHandle) else { return }
        credential = DevPasskeyCredentialRecord(
            userHandle: credential.userHandle,
            credentialID: credential.credentialID,
            privateKeyRawRepresentation: credential.privateKeyRawRepresentation,
            publicKeyRawRepresentation: credential.publicKeyRawRepresentation,
            signCount: signCount
        )
        try saveCredential(credential)
    }

    private func accountKey(for userHandle: String) -> String {
        "credential.\(userHandle)"
    }

    private func readData(account: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw DevPasskeyStoreError.keychain(status)
        }

        return item as? Data
    }

    private func writeData(_ data: Data, account: String) throws {
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
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw DevPasskeyStoreError.keychain(status)
        }
    }
}
