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
    let senderIdentityKey: String              // signing public key
    let senderIdentityAgreementKey: String     // agreement public key
    let ephemeralPublicKey: String
    let signature: String
    let oneTimePrekeyId: String?
    let handshakeMode: HandshakeMode
}

enum E2EEError: LocalizedError {
    case noAuthenticatedUser
    case invalidRecipientIdentityKey
    case invalidRecipientIdentityAgreementKey
    case invalidRecipientSignedPrekey
    case invalidRecipientSignedPrekeySignature
    case invalidRecipientOneTimePrekey
    case invalidHeader
    case invalidSenderIdentityKey
    case invalidSenderIdentityAgreementKey
    case invalidEphemeralPublicKey
    case invalidCiphertext
    case invalidSignature
    case missingRequiredLocalOneTimePrekey
    case decryptionFailed

    var errorDescription: String? {
        switch self {
        case .noAuthenticatedUser:
            return "No authenticated user is available for E2EE operations."
        case .invalidRecipientIdentityKey:
            return "Recipient signing identity key is invalid."
        case .invalidRecipientIdentityAgreementKey:
            return "Recipient agreement identity key is invalid."
        case .invalidRecipientSignedPrekey:
            return "Recipient signed prekey is invalid."
        case .invalidRecipientSignedPrekeySignature:
            return "Recipient signed prekey signature is invalid."
        case .invalidRecipientOneTimePrekey:
            return "Recipient one-time prekey is invalid."
        case .invalidHeader:
            return "Encrypted message header is invalid."
        case .invalidSenderIdentityKey:
            return "Sender signing identity key is invalid."
        case .invalidSenderIdentityAgreementKey:
            return "Sender agreement identity key is invalid."
        case .invalidEphemeralPublicKey:
            return "Ephemeral public key is invalid."
        case .invalidCiphertext:
            return "Ciphertext is invalid."
        case .invalidSignature:
            return "Message signature verification failed."
        case .missingRequiredLocalOneTimePrekey:
            return "The message requires a local one-time prekey that is no longer available."
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

        guard let recipientIdentityAgreementKeyData = Data(base64Encoded: recipientBundle.identityAgreementKey) else {
            throw E2EEError.invalidRecipientIdentityAgreementKey
        }

        guard let recipientSignedPrekeyData = Data(base64Encoded: recipientBundle.signedPrekey) else {
            throw E2EEError.invalidRecipientSignedPrekey
        }

        let recipientIdentityAgreementPublicKey = try Curve25519.KeyAgreement.PublicKey(
            rawRepresentation: recipientIdentityAgreementKeyData
        )

        let recipientSignedPrekeyPublicKey = try Curve25519.KeyAgreement.PublicKey(
            rawRepresentation: recipientSignedPrekeyData
        )

        let senderSigningPublicKeyData = senderMaterial.identitySigningPrivateKey.publicKey.rawRepresentation
        let senderAgreementPublicKeyData = senderMaterial.identityAgreementPrivateKey.publicKey.rawRepresentation

        let ephemeralPrivateKey = Curve25519.KeyAgreement.PrivateKey()
        let ephemeralPublicKeyData = ephemeralPrivateKey.publicKey.rawRepresentation

        let handshakeMode: HandshakeMode
        let oneTimePrekeyId: String?
        let symmetricKey: SymmetricKey

        if
            let recipientOneTimePrekey = recipientBundle.oneTimePrekey,
            let recipientOneTimePrekeyID = recipientBundle.oneTimePrekeyId
        {
            guard let recipientOneTimePrekeyData = Data(base64Encoded: recipientOneTimePrekey) else {
                throw E2EEError.invalidRecipientOneTimePrekey
            }

            let recipientOneTimePrekeyPublicKey = try Curve25519.KeyAgreement.PublicKey(
                rawRepresentation: recipientOneTimePrekeyData
            )

            let dh1 = try senderMaterial.identityAgreementPrivateKey.sharedSecretFromKeyAgreement(
                with: recipientSignedPrekeyPublicKey
            )
            let dh2 = try ephemeralPrivateKey.sharedSecretFromKeyAgreement(
                with: recipientIdentityAgreementPublicKey
            )
            let dh3 = try ephemeralPrivateKey.sharedSecretFromKeyAgreement(
                with: recipientSignedPrekeyPublicKey
            )
            let dh4 = try ephemeralPrivateKey.sharedSecretFromKeyAgreement(
                with: recipientOneTimePrekeyPublicKey
            )

            symmetricKey = deriveInitialSessionKey(
                dhParts: [dh1, dh2, dh3, dh4],
                conversationID: conversationID,
                senderUserID: senderUserID,
                recipientUserID: recipientBundle.userID,
                senderSigningIdentityKeyData: senderSigningPublicKeyData,
                senderAgreementIdentityKeyData: senderAgreementPublicKeyData
            )

            handshakeMode = .prekey
            oneTimePrekeyId = recipientOneTimePrekeyID
        } else {
            let dh1 = try ephemeralPrivateKey.sharedSecretFromKeyAgreement(
                with: recipientSignedPrekeyPublicKey
            )

            symmetricKey = deriveInitialSessionKey(
                dhParts: [dh1],
                conversationID: conversationID,
                senderUserID: senderUserID,
                recipientUserID: recipientBundle.userID,
                senderSigningIdentityKeyData: senderSigningPublicKeyData,
                senderAgreementIdentityKeyData: senderAgreementPublicKeyData
            )

            handshakeMode = .fallback
            oneTimePrekeyId = nil
        }

        let plaintextData = Data(plaintext.utf8)
        let sealedBox = try AES.GCM.seal(plaintextData, using: symmetricKey)

        guard let sealedCombined = sealedBox.combined else {
            throw E2EEError.invalidCiphertext
        }

        let signedContext = signingContext(
            version: 2,
            conversationID: conversationID,
            senderUserID: senderUserID,
            recipientUserID: recipientBundle.userID,
            senderIdentityAgreementKeyData: senderAgreementPublicKeyData,
            ephemeralPublicKeyData: ephemeralPublicKeyData,
            oneTimePrekeyId: oneTimePrekeyId,
            handshakeMode: handshakeMode,
            sealedCombined: sealedCombined
        )

        let signature = try senderMaterial.identitySigningPrivateKey.signature(for: signedContext)

        let header = E2EEHeader(
            version: 2,
            senderIdentityKey: senderSigningPublicKeyData.base64EncodedString(),
            senderIdentityAgreementKey: senderAgreementPublicKeyData.base64EncodedString(),
            ephemeralPublicKey: ephemeralPublicKeyData.base64EncodedString(),
            signature: signature.base64EncodedString(),
            oneTimePrekeyId: oneTimePrekeyId,
            handshakeMode: handshakeMode
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

        let senderSigningPublicKey = try Curve25519.Signing.PublicKey(
            rawRepresentation: senderIdentityKeyData
        )

        guard let senderIdentityAgreementKeyData = Data(base64Encoded: header.senderIdentityAgreementKey) else {
            throw E2EEError.invalidSenderIdentityAgreementKey
        }

        let senderAgreementPublicKey = try Curve25519.KeyAgreement.PublicKey(
            rawRepresentation: senderIdentityAgreementKeyData
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

        let recipientMaterial = try localKeyStore.ensureLocalIdentityMaterial(for: recipientUserID)

        let symmetricKey: SymmetricKey
        let consumedOneTimePrekeyId: String?

        switch header.handshakeMode {
        case .prekey:
            guard let oneTimePrekeyId = header.oneTimePrekeyId else {
                throw E2EEError.invalidHeader
            }

            guard let localOPK = try localKeyStore.oneTimePrekeyPrivateKey(
                for: recipientUserID,
                id: oneTimePrekeyId
            ) else {
                throw E2EEError.missingLocalOneTimePrekey
            }

            let dh1 = try recipientMaterial.signedPrekeyPrivateKey.sharedSecretFromKeyAgreement(
                with: senderAgreementPublicKey
            )
            let dh2 = try recipientMaterial.identityAgreementPrivateKey.sharedSecretFromKeyAgreement(
                with: ephemeralPublicKey
            )
            let dh3 = try recipientMaterial.signedPrekeyPrivateKey.sharedSecretFromKeyAgreement(
                with: ephemeralPublicKey
            )
            let dh4 = try localOPK.sharedSecretFromKeyAgreement(
                with: ephemeralPublicKey
            )

            symmetricKey = deriveInitialSessionKey(
                dhParts: [dh1, dh2, dh3, dh4],
                conversationID: envelope.conversationID,
                senderUserID: envelope.senderUserID,
                recipientUserID: envelope.recipientUserID,
                senderSigningIdentityKeyData: senderIdentityKeyData,
                senderAgreementIdentityKeyData: senderIdentityAgreementKeyData
            )

            consumedOneTimePrekeyId = oneTimePrekeyId

        case .fallback:
            let dh1 = try recipientMaterial.signedPrekeyPrivateKey.sharedSecretFromKeyAgreement(
                with: ephemeralPublicKey
            )

            symmetricKey = deriveInitialSessionKey(
                dhParts: [dh1],
                conversationID: envelope.conversationID,
                senderUserID: envelope.senderUserID,
                recipientUserID: envelope.recipientUserID,
                senderSigningIdentityKeyData: senderIdentityKeyData,
                senderAgreementIdentityKeyData: senderIdentityAgreementKeyData
            )

            consumedOneTimePrekeyId = nil
        }

        let signedContext = signingContext(
            version: header.version,
            conversationID: envelope.conversationID,
            senderUserID: envelope.senderUserID,
            recipientUserID: envelope.recipientUserID,
            senderIdentityAgreementKeyData: senderIdentityAgreementKeyData,
            ephemeralPublicKeyData: ephemeralPublicKeyData,
            oneTimePrekeyId: header.oneTimePrekeyId,
            handshakeMode: header.handshakeMode,
            sealedCombined: sealedCombined
        )

        guard senderSigningPublicKey.isValidSignature(signatureData, for: signedContext) else {
            throw E2EEError.invalidSignature
        }

        do {
            let sealedBox = try AES.GCM.SealedBox(combined: sealedCombined)
            let plaintextData = try AES.GCM.open(sealedBox, using: symmetricKey)
            let plaintext = String(decoding: plaintextData, as: UTF8.self)

            if let oneTimePrekeyId = consumedOneTimePrekeyId {
                try localKeyStore.consumeOneTimePrekey(
                    for: recipientUserID,
                    id: oneTimePrekeyId
                )
            }

            return DecryptedEnvelopeMessage(
                id: envelope.id,
                senderUserID: envelope.senderUserID,
                senderSigningIdentityKey: header.senderIdentityKey,
                senderAgreementIdentityKey: header.senderIdentityAgreementKey,
                conversationID: envelope.conversationID,
                plaintext: plaintext,
                createdAt: envelope.createdAt
            )
        } catch {
            throw E2EEError.decryptionFailed
        }
    }

    private func verifyRecipientBundle(_ bundle: RecipientKeyBundle) throws {
        guard let signingIdentityKeyData = Data(base64Encoded: bundle.identityKey) else {
            throw E2EEError.invalidRecipientIdentityKey
        }

        guard Data(base64Encoded: bundle.identityAgreementKey) != nil else {
            throw E2EEError.invalidRecipientIdentityAgreementKey
        }

        guard let signedPrekeyData = Data(base64Encoded: bundle.signedPrekey) else {
            throw E2EEError.invalidRecipientSignedPrekey
        }

        guard let signatureData = Data(base64Encoded: bundle.signedPrekeySignature) else {
            throw E2EEError.invalidRecipientSignedPrekeySignature
        }

        let signingIdentityPublicKey = try Curve25519.Signing.PublicKey(
            rawRepresentation: signingIdentityKeyData
        )

        guard signingIdentityPublicKey.isValidSignature(signatureData, for: signedPrekeyData) else {
            throw E2EEError.invalidRecipientSignedPrekeySignature
        }
    }

    private func deriveInitialSessionKey(
        dhParts: [SharedSecret],
        conversationID: UUID,
        senderUserID: String,
        recipientUserID: String,
        senderSigningIdentityKeyData: Data,
        senderAgreementIdentityKeyData: Data
    ) -> SymmetricKey {
        var ikm = Data()
        for part in dhParts {
            ikm.append(part.withUnsafeBytes { Data($0) })
        }

        let inputKeyMaterial = SymmetricKey(data: ikm)

        return HKDF<SHA256>.deriveKey(
            inputKeyMaterial: inputKeyMaterial,
            salt: protocolSalt,
            info: sharedInfo(
                conversationID: conversationID,
                senderUserID: senderUserID,
                recipientUserID: recipientUserID,
                senderSigningIdentityKeyData: senderSigningIdentityKeyData,
                senderAgreementIdentityKeyData: senderAgreementIdentityKeyData
            ),
            outputByteCount: 32
        )
    }

    private func currentUserID() async throws -> String {
        let current = await MainActor.run { session.currentUserID }
        guard let current, !current.isEmpty else {
            throw E2EEError.noAuthenticatedUser
        }
        return current
    }

    private var protocolSalt: Data {
        Data("VilLovChat-E2EE-v2".utf8)
    }

    private func sharedInfo(
        conversationID: UUID,
        senderUserID: String,
        recipientUserID: String,
        senderSigningIdentityKeyData: Data,
        senderAgreementIdentityKeyData: Data
    ) -> Data {
        var data = Data()
        data.append(Data("VilLovChat-X3DH-v2".utf8))
        data.append(Data(conversationID.uuidString.utf8))
        data.append(Data(senderUserID.utf8))
        data.append(Data(recipientUserID.utf8))
        data.append(senderSigningIdentityKeyData)
        data.append(senderAgreementIdentityKeyData)
        return data
    }

    private func signingContext(
        version: Int,
        conversationID: UUID,
        senderUserID: String,
        recipientUserID: String,
        senderIdentityAgreementKeyData: Data,
        ephemeralPublicKeyData: Data,
        oneTimePrekeyId: String?,
        handshakeMode: HandshakeMode,
        sealedCombined: Data
    ) -> Data {
        var data = Data()
        data.append(Data("VilLovChat-E2EE-sign-v2".utf8))
        data.append(Data(String(version).utf8))
        data.append(Data(conversationID.uuidString.utf8))
        data.append(Data(senderUserID.utf8))
        data.append(Data(recipientUserID.utf8))
        data.append(senderIdentityAgreementKeyData)
        data.append(ephemeralPublicKeyData)
        data.append(Data((oneTimePrekeyId ?? "").utf8))
        data.append(Data(handshakeMode.rawValue.utf8))
        data.append(sealedCombined)
        return data
    }
}
