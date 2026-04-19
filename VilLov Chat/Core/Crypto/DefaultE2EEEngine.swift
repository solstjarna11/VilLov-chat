//
//  DefaultE2EEEngine.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 18.4.2026.
//


import Foundation
import CryptoKit

private struct E2EEHeader: Codable {
    let version: Int
    let senderIdentityKey: String
    let ephemeralPublicKey: String
    let signature: String
}

enum E2EEError: LocalizedError {
    case noAuthenticatedUser
    case invalidRecipientIdentityKey
    case invalidRecipientSignedPrekey
    case invalidRecipientSignedPrekeySignature
    case invalidHeader
    case invalidSenderIdentityKey
    case invalidEphemeralPublicKey
    case invalidCiphertext
    case invalidSignature
    case decryptionFailed

    var errorDescription: String? {
        switch self {
        case .noAuthenticatedUser:
            return "No authenticated user is available for E2EE operations."
        case .invalidRecipientIdentityKey:
            return "Recipient identity key is invalid."
        case .invalidRecipientSignedPrekey:
            return "Recipient signed prekey is invalid."
        case .invalidRecipientSignedPrekeySignature:
            return "Recipient signed prekey signature is invalid."
        case .invalidHeader:
            return "Encrypted message header is invalid."
        case .invalidSenderIdentityKey:
            return "Sender identity key is invalid."
        case .invalidEphemeralPublicKey:
            return "Ephemeral public key is invalid."
        case .invalidCiphertext:
            return "Ciphertext is invalid."
        case .invalidSignature:
            return "Message signature verification failed."
        case .decryptionFailed:
            return "Message decryption failed."
        }
    }
}

final class DefaultE2EEEngine: E2EEEngine {
    private let localKeyStore: LocalKeyStore
    private let session: AppSession

    init(
        localKeyStore: LocalKeyStore,
        session: AppSession
    ) {
        self.localKeyStore = localKeyStore
        self.session = session
    }

    func ensureSession(
        with recipientUserID: String,
        bundle: RecipientKeyBundle
    ) async throws {
        _ = recipientUserID
        _ = try await currentUserID()
        try verifyRecipientBundle(bundle)
    }

    func encrypt(
        plaintext: String,
        recipientBundle: RecipientKeyBundle,
        conversationID: UUID
    ) async throws -> (ciphertext: String, header: String) {
        let senderUserID = try await currentUserID()
        let senderMaterial = try localKeyStore.ensureLocalIdentityMaterial(for: senderUserID)

        try verifyRecipientBundle(recipientBundle)

        guard let recipientSignedPrekeyData = Data(base64Encoded: recipientBundle.signedPrekey) else {
            throw E2EEError.invalidRecipientSignedPrekey
        }

        let recipientSignedPrekeyPublicKey = try Curve25519.KeyAgreement.PublicKey(
            rawRepresentation: recipientSignedPrekeyData
        )

        let ephemeralPrivateKey = Curve25519.KeyAgreement.PrivateKey()
        let ephemeralPublicKeyData = ephemeralPrivateKey.publicKey.rawRepresentation

        let sharedSecret = try ephemeralPrivateKey.sharedSecretFromKeyAgreement(
            with: recipientSignedPrekeyPublicKey
        )

        let senderIdentityKeyData = senderMaterial.identitySigningPrivateKey.publicKey.rawRepresentation

        let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: protocolSalt,
            sharedInfo: sharedInfo(
                conversationID: conversationID,
                senderUserID: senderUserID,
                recipientUserID: recipientBundle.userID,
                senderIdentityKeyData: senderIdentityKeyData
            ),
            outputByteCount: 32
        )

        let plaintextData = Data(plaintext.utf8)
        let sealedBox = try AES.GCM.seal(plaintextData, using: symmetricKey)

        guard let sealedCombined = sealedBox.combined else {
            throw E2EEError.invalidCiphertext
        }

        let signedContext = signingContext(
            conversationID: conversationID,
            senderUserID: senderUserID,
            recipientUserID: recipientBundle.userID,
            ephemeralPublicKeyData: ephemeralPublicKeyData,
            sealedCombined: sealedCombined
        )

        let signature = try senderMaterial.identitySigningPrivateKey.signature(for: signedContext)

        let header = E2EEHeader(
            version: 1,
            senderIdentityKey: senderIdentityKeyData.base64EncodedString(),
            ephemeralPublicKey: ephemeralPublicKeyData.base64EncodedString(),
            signature: signature.base64EncodedString()
        )

        let headerData = try JSONEncoder().encode(header)

        return (
            ciphertext: sealedCombined.base64EncodedString(),
            header: headerData.base64EncodedString()
        )
    }

    func decrypt(
        envelope: CiphertextEnvelope
    ) async throws -> DecryptedEnvelopeMessage {
        let recipientUserID = try await currentUserID()

        guard recipientUserID == envelope.recipientUserID else {
            throw E2EEError.noAuthenticatedUser
        }

        guard let headerData = Data(base64Encoded: envelope.header) else {
            throw E2EEError.invalidHeader
        }

        let header = try JSONDecoder().decode(E2EEHeader.self, from: headerData)

        guard let senderIdentityKeyData = Data(base64Encoded: header.senderIdentityKey) else {
            throw E2EEError.invalidSenderIdentityKey
        }

        let senderIdentityPublicKey = try Curve25519.Signing.PublicKey(
            rawRepresentation: senderIdentityKeyData
        )

        guard let ephemeralPublicKeyData = Data(base64Encoded: header.ephemeralPublicKey) else {
            throw E2EEError.invalidEphemeralPublicKey
        }

        let ephemeralPublicKey = try Curve25519.KeyAgreement.PublicKey(
            rawRepresentation: ephemeralPublicKeyData
        )

        guard let signatureData = Data(base64Encoded: header.signature) else {
            throw E2EEError.invalidSignature
        }

        guard let sealedCombined = Data(base64Encoded: envelope.ciphertext) else {
            throw E2EEError.invalidCiphertext
        }

        let recipientSignedPrekeyPrivateKey = try localKeyStore.signedPrekeyPrivateKey(for: recipientUserID)

        let sharedSecret = try recipientSignedPrekeyPrivateKey.sharedSecretFromKeyAgreement(
            with: ephemeralPublicKey
        )

        let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: protocolSalt,
            sharedInfo: sharedInfo(
                conversationID: envelope.conversationID,
                senderUserID: envelope.senderUserID,
                recipientUserID: envelope.recipientUserID,
                senderIdentityKeyData: senderIdentityKeyData
            ),
            outputByteCount: 32
        )

        let signedContext = signingContext(
            conversationID: envelope.conversationID,
            senderUserID: envelope.senderUserID,
            recipientUserID: envelope.recipientUserID,
            ephemeralPublicKeyData: ephemeralPublicKeyData,
            sealedCombined: sealedCombined
        )

        guard senderIdentityPublicKey.isValidSignature(signatureData, for: signedContext) else {
            throw E2EEError.invalidSignature
        }

        do {
            let sealedBox = try AES.GCM.SealedBox(combined: sealedCombined)
            let plaintextData = try AES.GCM.open(sealedBox, using: symmetricKey)
            let plaintext = String(decoding: plaintextData, as: UTF8.self)

            return DecryptedEnvelopeMessage(
                id: envelope.id,
                senderUserID: envelope.senderUserID,
                senderIdentityKey: header.senderIdentityKey,
                conversationID: envelope.conversationID,
                plaintext: plaintext,
                createdAt: envelope.createdAt
            )
        } catch {
            throw E2EEError.decryptionFailed
        }
    }

    private func verifyRecipientBundle(_ bundle: RecipientKeyBundle) throws {
        guard let identityKeyData = Data(base64Encoded: bundle.identityKey) else {
            throw E2EEError.invalidRecipientIdentityKey
        }

        guard let signedPrekeyData = Data(base64Encoded: bundle.signedPrekey) else {
            throw E2EEError.invalidRecipientSignedPrekey
        }

        guard let signatureData = Data(base64Encoded: bundle.signedPrekeySignature) else {
            throw E2EEError.invalidRecipientSignedPrekeySignature
        }

        let identityPublicKey = try Curve25519.Signing.PublicKey(rawRepresentation: identityKeyData)

        guard identityPublicKey.isValidSignature(signatureData, for: signedPrekeyData) else {
            throw E2EEError.invalidRecipientSignedPrekeySignature
        }
    }

    private func currentUserID() async throws -> String {
        let current = await MainActor.run { session.currentUserID }
        guard let current, !current.isEmpty else {
            throw E2EEError.noAuthenticatedUser
        }
        return current
    }

    private var protocolSalt: Data {
        Data("VilLovChat-E2EE-v1".utf8)
    }

    private func sharedInfo(
        conversationID: UUID,
        senderUserID: String,
        recipientUserID: String,
        senderIdentityKeyData: Data
    ) -> Data {
        var data = Data()
        data.append(Data(conversationID.uuidString.utf8))
        data.append(Data(senderUserID.utf8))
        data.append(Data(recipientUserID.utf8))
        data.append(senderIdentityKeyData)
        return data
    }

    private func signingContext(
        conversationID: UUID,
        senderUserID: String,
        recipientUserID: String,
        ephemeralPublicKeyData: Data,
        sealedCombined: Data
    ) -> Data {
        var data = Data()
        data.append(Data("VilLovChat-E2EE-sign-v1".utf8))
        data.append(Data(conversationID.uuidString.utf8))
        data.append(Data(senderUserID.utf8))
        data.append(Data(recipientUserID.utf8))
        data.append(ephemeralPublicKeyData)
        data.append(sealedCombined)
        return data
    }
}
