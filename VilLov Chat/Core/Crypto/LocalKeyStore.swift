//
//  LocalKeyStore.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 18.4.2026.
//


import Foundation
import CryptoKit
import Security

struct LocalIdentityMaterial {
    let identitySigningPrivateKey: Curve25519.Signing.PrivateKey
    let signedPrekeyPrivateKey: Curve25519.KeyAgreement.PrivateKey
}

enum LocalKeyStoreError: Error {
    case invalidStoredKeyMaterial
    case keychainStoreFailed(OSStatus)
    case keychainLoadFailed(OSStatus)
}

final class LocalKeyStore {
    private let service = "com.villovchat.keys"

    func ensureLocalIdentityMaterial(for userID: String) throws -> LocalIdentityMaterial {
        let identityTag = identitySigningPrivateKeyTag(for: userID)
        let prekeyTag = signedPrekeyPrivateKeyTag(for: userID)

        let identityPrivateKey: Curve25519.Signing.PrivateKey
        let signedPrekeyPrivateKey: Curve25519.KeyAgreement.PrivateKey

        if let identityData = try loadKey(tag: identityTag) {
            identityPrivateKey = try Curve25519.Signing.PrivateKey(rawRepresentation: identityData)
        } else {
            let newKey = Curve25519.Signing.PrivateKey()
            try saveKey(newKey.rawRepresentation, tag: identityTag)
            identityPrivateKey = newKey
        }

        if let prekeyData = try loadKey(tag: prekeyTag) {
            signedPrekeyPrivateKey = try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: prekeyData)
        } else {
            let newKey = Curve25519.KeyAgreement.PrivateKey()
            try saveKey(newKey.rawRepresentation, tag: prekeyTag)
            signedPrekeyPrivateKey = newKey
        }

        return LocalIdentityMaterial(
            identitySigningPrivateKey: identityPrivateKey,
            signedPrekeyPrivateKey: signedPrekeyPrivateKey
        )
    }

    func uploadBundleRequest(for userID: String) throws -> UploadKeyBundleRequest {
        let material = try ensureLocalIdentityMaterial(for: userID)

        let identityPublicKey = material.identitySigningPrivateKey.publicKey.rawRepresentation
        let signedPrekeyPublicKey = material.signedPrekeyPrivateKey.publicKey.rawRepresentation

        let signature = try material.identitySigningPrivateKey.signature(for: signedPrekeyPublicKey)

        return UploadKeyBundleRequest(
            userID: userID,
            identityKey: identityPublicKey.base64EncodedString(),
            signedPrekey: signedPrekeyPublicKey.base64EncodedString(),
            signedPrekeySignature: signature.base64EncodedString(),
            oneTimePrekey: nil
        )
    }

    func identitySigningPrivateKey(for userID: String) throws -> Curve25519.Signing.PrivateKey {
        let material = try ensureLocalIdentityMaterial(for: userID)
        return material.identitySigningPrivateKey
    }

    func signedPrekeyPrivateKey(for userID: String) throws -> Curve25519.KeyAgreement.PrivateKey {
        let material = try ensureLocalIdentityMaterial(for: userID)
        return material.signedPrekeyPrivateKey
    }

    func identitySigningPublicKeyBase64(for userID: String) throws -> String {
        let material = try ensureLocalIdentityMaterial(for: userID)
        return material.identitySigningPrivateKey.publicKey.rawRepresentation.base64EncodedString()
    }

    private func identitySigningPrivateKeyTag(for userID: String) -> String {
        "\(service).identity-signing.\(userID)"
    }

    private func signedPrekeyPrivateKeyTag(for userID: String) -> String {
        "\(service).signed-prekey.\(userID)"
    }

    private func saveKey(_ data: Data, tag: String) throws {
        let tagData = Data(tag.utf8)

        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tag,
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tag,
            kSecAttrGeneric as String: tagData,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw LocalKeyStoreError.keychainStoreFailed(status)
        }
    }

    private func loadKey(tag: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tag,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let data = result as? Data else {
                throw LocalKeyStoreError.invalidStoredKeyMaterial
            }
            return data
        case errSecItemNotFound:
            return nil
        default:
            throw LocalKeyStoreError.keychainLoadFailed(status)
        }
    }
}
