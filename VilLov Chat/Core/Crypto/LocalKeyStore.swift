//
//  LocalKeyStore.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 18.4.2026.
//


import Foundation
import CryptoKit
import Security

struct SignedPrekeyMaterial: Codable, Equatable {
    let id: String
    let createdAt: Date
    let privateKeyRaw: Data

    var privateKey: Curve25519.KeyAgreement.PrivateKey {
        get throws {
            try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: privateKeyRaw)
        }
    }

    var publicKey: Curve25519.KeyAgreement.PublicKey {
        get throws { try privateKey.publicKey }
    }

    var publicKeyData: Data {
        get throws { try publicKey.rawRepresentation }
    }

    var publicKeyBase64: String {
        get throws { try publicKeyData.base64EncodedString() }
    }
}

struct LocalIdentityMaterial {
    let identitySigningPrivateKey: Curve25519.Signing.PrivateKey
    let identityAgreementPrivateKey: Curve25519.KeyAgreement.PrivateKey
    let currentSignedPrekey: SignedPrekeyMaterial
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
    case missingCurrentSignedPrekey
}

final class LocalKeyStore {
    private let service = "com.villovchat.keys"

    func ensureLocalIdentityMaterial(for userID: String) throws -> LocalIdentityMaterial {
        let signingTag = identitySigningPrivateKeyTag(for: userID)
        let agreementTag = identityAgreementPrivateKeyTag(for: userID)

        let signingPrivateKey: Curve25519.Signing.PrivateKey
        let agreementPrivateKey: Curve25519.KeyAgreement.PrivateKey

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

        let currentSignedPrekey = try ensureCurrentSignedPrekey(for: userID)

        return LocalIdentityMaterial(
            identitySigningPrivateKey: signingPrivateKey,
            identityAgreementPrivateKey: agreementPrivateKey,
            currentSignedPrekey: currentSignedPrekey
        )
    }

    func currentSignedPrekey(for userID: String) throws -> SignedPrekeyMaterial {
        try ensureCurrentSignedPrekey(for: userID)
    }

    @discardableResult
    func rotateSignedPrekey(for userID: String) throws -> SignedPrekeyMaterial {
        let newSignedPrekey = SignedPrekeyMaterial(
            id: UUID().uuidString.lowercased(),
            createdAt: Date(),
            privateKeyRaw: Curve25519.KeyAgreement.PrivateKey().rawRepresentation
        )

        try saveSignedPrekey(newSignedPrekey, for: userID)
        try saveCurrentSignedPrekeyID(newSignedPrekey.id, for: userID)
        return newSignedPrekey
    }

    func signedPrekeyPrivateKey(
        for userID: String,
        id: String
    ) throws -> Curve25519.KeyAgreement.PrivateKey? {
        guard let record = try loadSignedPrekey(for: userID, id: id) else {
            return nil
        }
        return try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: record.privateKeyRaw)
    }

    func purgeRetiredSignedPrekeys(
        for userID: String,
        olderThan cutoff: Date
    ) throws {
        guard let currentID = try loadCurrentSignedPrekeyID(for: userID) else {
            return
        }

        let ids = try listSignedPrekeyIDs(for: userID)

        for id in ids where id != currentID {
            guard let record = try loadSignedPrekey(for: userID, id: id) else { continue }
            if record.createdAt < cutoff {
                try deleteKey(tag: signedPrekeyPrivateKeyTag(for: userID, id: id))
            }
        }
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
        let signedPrekeyPublicKey = try material.currentSignedPrekey.publicKeyData

        let signaturePayload = signedPrekeySignaturePayload(
            signedPrekeyID: material.currentSignedPrekey.id,
            signedPrekeyPublicKey: signedPrekeyPublicKey
        )

        let signature = try material.identitySigningPrivateKey.signature(for: signaturePayload)

        return UploadKeyBundleRequest(
            userID: userID,
            identityKey: signingPublicKey.base64EncodedString(),
            identityAgreementKey: agreementPublicKey.base64EncodedString(),
            signedPrekeyId: material.currentSignedPrekey.id,
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
        let signedPrekey = try ensureLocalIdentityMaterial(for: userID).currentSignedPrekey
        return try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: signedPrekey.privateKeyRaw)
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

    func signedPrekeySignaturePayload(
        signedPrekeyID: String,
        signedPrekeyPublicKey: Data
    ) -> Data {
        var data = Data()
        data.append(Data("VilLovChat-SignedPrekey-v1".utf8))
        data.append(Data(signedPrekeyID.utf8))
        data.append(Data([0x00]))
        data.append(signedPrekeyPublicKey)
        return data
    }

    private func ensureCurrentSignedPrekey(for userID: String) throws -> SignedPrekeyMaterial {
        if let currentID = try loadCurrentSignedPrekeyID(for: userID),
           let existing = try loadSignedPrekey(for: userID, id: currentID) {
            return existing
        }

        let initial = SignedPrekeyMaterial(
            id: UUID().uuidString.lowercased(),
            createdAt: Date(),
            privateKeyRaw: Curve25519.KeyAgreement.PrivateKey().rawRepresentation
        )

        try saveSignedPrekey(initial, for: userID)
        try saveCurrentSignedPrekeyID(initial.id, for: userID)
        return initial
    }

    private func saveSignedPrekey(
        _ signedPrekey: SignedPrekeyMaterial,
        for userID: String
    ) throws {
        let data = try JSONEncoder().encode(signedPrekey)
        try saveKey(data, tag: signedPrekeyPrivateKeyTag(for: userID, id: signedPrekey.id))
    }

    private func loadSignedPrekey(
        for userID: String,
        id: String
    ) throws -> SignedPrekeyMaterial? {
        let tag = signedPrekeyPrivateKeyTag(for: userID, id: id)
        guard let data = try loadKey(tag: tag) else {
            return nil
        }
        return try JSONDecoder().decode(SignedPrekeyMaterial.self, from: data)
    }

    private func saveCurrentSignedPrekeyID(
        _ id: String,
        for userID: String
    ) throws {
        try saveKey(Data(id.utf8), tag: signedPrekeyCurrentTag(for: userID))
    }

    private func loadCurrentSignedPrekeyID(for userID: String) throws -> String? {
        guard let data = try loadKey(tag: signedPrekeyCurrentTag(for: userID)) else {
            return nil
        }
        return String(decoding: data, as: UTF8.self)
    }

    private func listSignedPrekeyIDs(for userID: String) throws -> [String] {
        let prefix = "\(service).signed-prekey.\(userID)."

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let items = result as? [[String: Any]] else {
                throw LocalKeyStoreError.invalidStoredKeyMaterial
            }

            return items.compactMap { item in
                guard let account = item[kSecAttrAccount as String] as? String else { return nil }
                guard account.hasPrefix(prefix) else { return nil }
                return String(account.dropFirst(prefix.count))
            }

        case errSecItemNotFound:
            return []

        default:
            throw LocalKeyStoreError.keychainLoadFailed(status)
        }
    }

    private func identitySigningPrivateKeyTag(for userID: String) -> String {
        "\(service).identity-signing.\(userID)"
    }

    private func identityAgreementPrivateKeyTag(for userID: String) -> String {
        "\(service).identity-agreement.\(userID)"
    }

    private func signedPrekeyCurrentTag(for userID: String) -> String {
        "\(service).signed-prekey.current.\(userID)"
    }

    private func signedPrekeyPrivateKeyTag(for userID: String, id: String) -> String {
        "\(service).signed-prekey.\(userID).\(id)"
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
