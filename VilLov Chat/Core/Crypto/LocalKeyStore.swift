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
    let identityAgreementPrivateKey: Curve25519.KeyAgreement.PrivateKey
    let signedPrekeyPrivateKey: Curve25519.KeyAgreement.PrivateKey
}


struct OneTimePrekeyMaterial {
    let id: String
    let privateKey: Curve25519.KeyAgreement.PrivateKey

    var publicKey: Curve25519.KeyAgreement.PublicKey {
        privateKey.publicKey
    }

    var publicKeyData: Data {
        publicKey.rawRepresentation
    }

    var publicKeyBase64: String {
        publicKeyData.base64EncodedString()
    }
}

enum LocalKeyStoreError: Error {
    case invalidStoredKeyMaterial
    case keychainStoreFailed(OSStatus)
    case keychainLoadFailed(OSStatus)
    case duplicateOneTimePrekeyID
}

final class LocalKeyStore {
    private let service = "com.villovchat.keys"

    func ensureLocalIdentityMaterial(for userID: String) throws -> LocalIdentityMaterial {
        let signingTag = identitySigningPrivateKeyTag(for: userID)
        let agreementTag = identityAgreementPrivateKeyTag(for: userID)
        let signedPrekeyTag = signedPrekeyPrivateKeyTag(for: userID)

        let signingPrivateKey: Curve25519.Signing.PrivateKey
        let agreementPrivateKey: Curve25519.KeyAgreement.PrivateKey
        let signedPrekeyPrivateKey: Curve25519.KeyAgreement.PrivateKey

        if let signingData = try loadKey(tag: signingTag) {
            signingPrivateKey = try Curve25519.Signing.PrivateKey(rawRepresentation: signingData)
        } else {
            let newKey = Curve25519.Signing.PrivateKey()
            try saveKey(newKey.rawRepresentation, tag: signingTag)
            signingPrivateKey = newKey
        }

        if let agreementData = try loadKey(tag: agreementTag) {
            agreementPrivateKey = try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: agreementData)
        } else {
            let newKey = Curve25519.KeyAgreement.PrivateKey()
            try saveKey(newKey.rawRepresentation, tag: agreementTag)
            agreementPrivateKey = newKey
        }

        if let prekeyData = try loadKey(tag: signedPrekeyTag) {
            signedPrekeyPrivateKey = try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: prekeyData)
        } else {
            let newKey = Curve25519.KeyAgreement.PrivateKey()
            try saveKey(newKey.rawRepresentation, tag: signedPrekeyTag)
            signedPrekeyPrivateKey = newKey
        }

        return LocalIdentityMaterial(
            identitySigningPrivateKey: signingPrivateKey,
            identityAgreementPrivateKey: agreementPrivateKey,
            signedPrekeyPrivateKey: signedPrekeyPrivateKey
        )
    }

    func generateOneTimePrekeys(
        for userID: String,
        count: Int
    ) throws -> [OneTimePrekeyMaterial] {
        guard count > 0 else { return [] }

        var results: [OneTimePrekeyMaterial] = []
        results.reserveCapacity(count)

        for _ in 0..<count {
            let id = UUID().uuidString.lowercased()
            let tag = oneTimePrekeyPrivateKeyTag(for: userID, id: id)

            if try loadKey(tag: tag) != nil {
                throw LocalKeyStoreError.duplicateOneTimePrekeyID
            }

            let privateKey = Curve25519.KeyAgreement.PrivateKey()
            try saveKey(privateKey.rawRepresentation, tag: tag)

            results.append(
                OneTimePrekeyMaterial(
                    id: id,
                    privateKey: privateKey
                )
            )
        }

        return results
    }

    func uploadBundleRequest(
        for userID: String,
        oneTimePrekeyCount: Int
    ) throws -> UploadKeyBundleRequest {
        let material = try ensureLocalIdentityMaterial(for: userID)
        let oneTimePrekeys = try generateOneTimePrekeys(for: userID, count: oneTimePrekeyCount)

        let signingPublicKey = material.identitySigningPrivateKey.publicKey.rawRepresentation
        let agreementPublicKey = material.identityAgreementPrivateKey.publicKey.rawRepresentation
        let signedPrekeyPublicKey = material.signedPrekeyPrivateKey.publicKey.rawRepresentation

        let signature = try material.identitySigningPrivateKey.signature(for: signedPrekeyPublicKey)

        return UploadKeyBundleRequest(
            userID: userID,
            identityKey: signingPublicKey.base64EncodedString(),
            identityAgreementKey: agreementPublicKey.base64EncodedString(),
            signedPrekey: signedPrekeyPublicKey.base64EncodedString(),
            signedPrekeySignature: signature.base64EncodedString(),
            oneTimePrekeys: oneTimePrekeys.map {
                OneTimePrekeyUpload(id: $0.id, publicKey: $0.publicKeyBase64)
            }
        )
    }

    func identitySigningPrivateKey(for userID: String) throws -> Curve25519.Signing.PrivateKey {
        try ensureLocalIdentityMaterial(for: userID).identitySigningPrivateKey
    }

    func identityAgreementPrivateKey(for userID: String) throws -> Curve25519.KeyAgreement.PrivateKey {
        try ensureLocalIdentityMaterial(for: userID).identityAgreementPrivateKey
    }

    func signedPrekeyPrivateKey(for userID: String) throws -> Curve25519.KeyAgreement.PrivateKey {
        try ensureLocalIdentityMaterial(for: userID).signedPrekeyPrivateKey
    }

    func oneTimePrekeyPrivateKey(
        for userID: String,
        id: String
    ) throws -> Curve25519.KeyAgreement.PrivateKey? {
        let tag = oneTimePrekeyPrivateKeyTag(for: userID, id: id)
        guard let data = try loadKey(tag: tag) else {
            return nil
        }
        return try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: data)
    }

    func consumeOneTimePrekey(
        for userID: String,
        id: String
    ) throws {
        try deleteKey(tag: oneTimePrekeyPrivateKeyTag(for: userID, id: id))
    }

    func identitySigningPublicKeyBase64(for userID: String) throws -> String {
        try ensureLocalIdentityMaterial(for: userID)
            .identitySigningPrivateKey
            .publicKey
            .rawRepresentation
            .base64EncodedString()
    }

    func identityAgreementPublicKeyBase64(for userID: String) throws -> String {
        try ensureLocalIdentityMaterial(for: userID)
            .identityAgreementPrivateKey
            .publicKey
            .rawRepresentation
            .base64EncodedString()
    }

    private func identitySigningPrivateKeyTag(for userID: String) -> String {
        "\(service).identity-signing.\(userID)"
    }

    private func identityAgreementPrivateKeyTag(for userID: String) -> String {
        "\(service).identity-agreement.\(userID)"
    }

    private func signedPrekeyPrivateKeyTag(for userID: String) -> String {
        "\(service).signed-prekey.\(userID)"
    }

    private func oneTimePrekeyPrivateKeyTag(for userID: String, id: String) -> String {
        "\(service).one-time-prekey.\(userID).\(id)"
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

    private func deleteKey(tag: String) throws {
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tag,
        ]

        let status = SecItemDelete(deleteQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw LocalKeyStoreError.keychainStoreFailed(status)
        }
    }
}
