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
    let senderIdentityAgreementKey: String
    let ephemeralPublicKey: String?
    let ratchetPublicKey: String?
    let signature: String
    let signedPrekeyId: String?
    let oneTimePrekeyId: String?
    let handshakeMode: HandshakeMode?
    let messageNumber: Int
    let previousChainLength: Int
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
    case invalidRatchetPublicKey
    case invalidCiphertext
    case invalidSignature
    case missingRequiredLocalOneTimePrekey
    case decryptionFailed
    case missingConversationPeer
    case missingSessionBootstrapMaterial
    case missingLocalRatchetKey
    case missingRequiredLocalSignedPrekey

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
        case .invalidRatchetPublicKey:
            return "Ratchet public key is invalid."
        case .invalidCiphertext:
            return "Ciphertext is invalid."
        case .invalidSignature:
            return "Message signature verification failed."
        case .missingRequiredLocalOneTimePrekey:
            return "The message requires a local one-time prekey that is no longer available."
        case .decryptionFailed:
            return "Message decryption failed."
        case .missingConversationPeer:
            return "Conversation peer information is missing."
        case .missingSessionBootstrapMaterial:
            return "Session bootstrap material is missing."
        case .missingLocalRatchetKey:
            return "Local ratchet key is missing."
        case .missingRequiredLocalSignedPrekey:
            return "The message requires a local signed prekey that is no longer available."
        }
    }
}

final class DefaultE2EEEngine: E2EEEngine {
    private let localKeyStore: LocalKeyStore
    private let localSessionStore: LocalSessionStore
    private let session: AppSession
    private let localSkippedKeyStore: LocalSkippedKeyStore
    private let maxSkipWindow = 50

    init(
        localKeyStore: LocalKeyStore,
        localSessionStore: LocalSessionStore,
        localSkippedKeyStore: LocalSkippedKeyStore,
        session: AppSession
    ) {
        self.localKeyStore = localKeyStore
        self.localSessionStore = localSessionStore
        self.localSkippedKeyStore = localSkippedKeyStore
        self.session = session
    }

    func ensureSession(
        with recipientUserID: String,
        bundle: RecipientKeyBundle
    ) async throws {
        let senderUserID = try await currentUserID()

        if localSessionStore.loadSession(
            conversationID: deterministicConversationID(localUserID: senderUserID, remoteUserID: recipientUserID),
            localUserID: senderUserID,
            remoteUserID: recipientUserID
        ) != nil {
            return
        }

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

        if let existing = localSessionStore.loadSession(
            conversationID: conversationID,
            localUserID: senderUserID,
            remoteUserID: recipientBundle.userID
        ) {
            return try encryptUsingExistingSession(
                plaintext: plaintext,
                conversationID: conversationID,
                recipientUserID: recipientBundle.userID,
                senderMaterial: senderMaterial,
                sessionState: existing
            )
        }

        return try bootstrapAndEncryptFirstMessage(
            plaintext: plaintext,
            recipientBundle: recipientBundle,
            conversationID: conversationID,
            senderUserID: senderUserID,
            senderMaterial: senderMaterial
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

        guard let sealedCombined = Data(base64Encoded: envelope.ciphertext) else {
            throw E2EEError.invalidCiphertext
        }

        let recipientMaterial = try localKeyStore.ensureLocalIdentityMaterial(for: recipientUserID)

        if let existing = localSessionStore.loadSession(
            conversationID: envelope.conversationID,
            localUserID: recipientUserID,
            remoteUserID: envelope.senderUserID
        ) {
            return try decryptUsingExistingSession(
                envelope: envelope,
                header: header,
                sealedCombined: sealedCombined,
                senderSigningPublicKey: senderSigningPublicKey,
                senderIdentityKeyData: senderIdentityKeyData,
                senderIdentityAgreementKeyData: senderIdentityAgreementKeyData,
                recipientUserID: recipientUserID,
                sessionState: existing
            )
        }

        return try bootstrapAndDecryptFirstMessage(
            envelope: envelope,
            header: header,
            sealedCombined: sealedCombined,
            senderSigningPublicKey: senderSigningPublicKey,
            senderIdentityKeyData: senderIdentityKeyData,
            senderIdentityAgreementKeyData: senderIdentityAgreementKeyData,
            recipientMaterial: recipientMaterial,
            recipientUserID: recipientUserID
        )
    }

    private func bootstrapAndEncryptFirstMessage(
        plaintext: String,
        recipientBundle: RecipientKeyBundle,
        conversationID: UUID,
        senderUserID: String,
        senderMaterial: LocalIdentityMaterial
    ) throws -> (ciphertext: String, header: String) {
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

        let initialRatchetPrivateKey = Curve25519.KeyAgreement.PrivateKey()
        let initialRatchetPublicKeyData = initialRatchetPrivateKey.publicKey.rawRepresentation

        let handshakeMode: HandshakeMode
        let oneTimePrekeyId: String?
        let initialRootKey: Data
        
        let recipientSignedPrekeyID = recipientBundle.signedPrekeyId

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

            let dh1 = try senderMaterial.identityAgreementPrivateKey.sharedSecretFromKeyAgreement(with: recipientSignedPrekeyPublicKey)
            let dh2 = try ephemeralPrivateKey.sharedSecretFromKeyAgreement(with: recipientIdentityAgreementPublicKey)
            let dh3 = try ephemeralPrivateKey.sharedSecretFromKeyAgreement(with: recipientSignedPrekeyPublicKey)
            let dh4 = try ephemeralPrivateKey.sharedSecretFromKeyAgreement(with: recipientOneTimePrekeyPublicKey)

            initialRootKey = deriveInitialRootKey(
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
            let dh1 = try ephemeralPrivateKey.sharedSecretFromKeyAgreement(with: recipientSignedPrekeyPublicKey)

            initialRootKey = deriveInitialRootKey(
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

        var sessionState = RatchetSession(
            id: UUID(),
            conversationID: conversationID,
            localUserID: senderUserID,
            remoteUserID: recipientBundle.userID,
            remoteSigningIdentityKey: recipientBundle.identityKey,
            remoteAgreementIdentityKey: recipientBundle.identityAgreementKey,
            rootKey: initialRootKey,
            sendingChainKey: DoubleRatchet.deriveInitialChainKey(rootKey: initialRootKey, label: "sender"),
            receivingChainKey: DoubleRatchet.deriveInitialChainKey(rootKey: initialRootKey, label: "receiver"),
            localRatchetPrivateKey: initialRatchetPrivateKey.rawRepresentation,
            remoteRatchetPublicKey: nil,
            sendMessageNumber: 0,
            receiveMessageNumber: 0,
            previousSendingChainLength: 0,
            createdAt: Date(),
            updatedAt: Date(),
            needsSendRatchet: false
        )

        let result = try encryptAndAdvanceSession(
            plaintext: plaintext,
            conversationID: conversationID,
            senderUserID: senderUserID,
            recipientUserID: recipientBundle.userID,
            senderSigningPrivateKey: senderMaterial.identitySigningPrivateKey,
            senderAgreementPublicKeyData: senderAgreementPublicKeyData,
            sessionState: &sessionState,
            bootstrapEphemeralPublicKeyData: ephemeralPublicKeyData,
            bootstrapHandshakeMode: handshakeMode,
            bootstrapSignedPrekeyId: recipientSignedPrekeyID,
            bootstrapOneTimePrekeyId: oneTimePrekeyId,
            ratchetPublicKeyData: initialRatchetPublicKeyData
        )

        try localSessionStore.saveSession(sessionState)
        return result
    }

    private func encryptUsingExistingSession(
        plaintext: String,
        conversationID: UUID,
        recipientUserID: String,
        senderMaterial: LocalIdentityMaterial,
        sessionState: RatchetSession
    ) throws -> (ciphertext: String, header: String) {
        var mutableSession = sessionState

        try performPendingSendRatchetIfNeeded(sessionState: &mutableSession)

        let localRatchetPrivateKeyData = mutableSession.localRatchetPrivateKey
        let localRatchetPrivateKey = try localRatchetPrivateKeyData.map {
            try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: $0)
        }

        let ratchetPublicKeyData = localRatchetPrivateKey?.publicKey.rawRepresentation

        let result = try encryptAndAdvanceSession(
            plaintext: plaintext,
            conversationID: conversationID,
            senderUserID: mutableSession.localUserID,
            recipientUserID: recipientUserID,
            senderSigningPrivateKey: senderMaterial.identitySigningPrivateKey,
            senderAgreementPublicKeyData: senderMaterial.identityAgreementPrivateKey.publicKey.rawRepresentation,
            sessionState: &mutableSession,
            bootstrapEphemeralPublicKeyData: nil,
            bootstrapHandshakeMode: nil,
            bootstrapSignedPrekeyId: nil,
            bootstrapOneTimePrekeyId: nil,
            ratchetPublicKeyData: ratchetPublicKeyData
        )

        try localSessionStore.saveSession(mutableSession)
        return result
    }

    private func encryptAndAdvanceSession(
        plaintext: String,
        conversationID: UUID,
        senderUserID: String,
        recipientUserID: String,
        senderSigningPrivateKey: Curve25519.Signing.PrivateKey,
        senderAgreementPublicKeyData: Data,
        sessionState: inout RatchetSession,
        bootstrapEphemeralPublicKeyData: Data?,
        bootstrapHandshakeMode: HandshakeMode?,
        bootstrapSignedPrekeyId: String?,
        bootstrapOneTimePrekeyId: String?,
        ratchetPublicKeyData: Data?
    ) throws -> (ciphertext: String, header: String) {
        guard let chainKey = sessionState.sendingChainKey else {
            throw E2EEError.missingSessionBootstrapMaterial
        }

        let chainStep = DoubleRatchet.deriveChainStep(from: chainKey)
        let messageNumber = sessionState.sendMessageNumber

        let plaintextData = Data(plaintext.utf8)
        let sealedBox = try AES.GCM.seal(plaintextData, using: chainStep.messageKey)

        guard let sealedCombined = sealedBox.combined else {
            throw E2EEError.invalidCiphertext
        }

        let signedContext = signingContext(
            version: 4,
            conversationID: conversationID,
            senderUserID: senderUserID,
            recipientUserID: recipientUserID,
            senderIdentityAgreementKeyData: senderAgreementPublicKeyData,
            ephemeralPublicKeyData: bootstrapEphemeralPublicKeyData ?? Data(),
            ratchetPublicKeyData: ratchetPublicKeyData ?? Data(),
            signedPrekeyId: bootstrapSignedPrekeyId,
            oneTimePrekeyId: bootstrapOneTimePrekeyId,
            handshakeMode: bootstrapHandshakeMode,
            messageNumber: messageNumber,
            previousChainLength: sessionState.previousSendingChainLength,
            sealedCombined: sealedCombined
        )

        let signature = try senderSigningPrivateKey.signature(for: signedContext)

        let header = E2EEHeader(
            version: 4,
            senderIdentityKey: senderSigningPrivateKey.publicKey.rawRepresentation.base64EncodedString(),
            senderIdentityAgreementKey: senderAgreementPublicKeyData.base64EncodedString(),
            ephemeralPublicKey: bootstrapEphemeralPublicKeyData?.base64EncodedString(),
            ratchetPublicKey: ratchetPublicKeyData?.base64EncodedString(),
            signature: signature.base64EncodedString(),
            signedPrekeyId: bootstrapSignedPrekeyId,
            oneTimePrekeyId: bootstrapOneTimePrekeyId,
            handshakeMode: bootstrapHandshakeMode,
            messageNumber: messageNumber,
            previousChainLength: sessionState.previousSendingChainLength
        )

        sessionState = RatchetSession(
            id: sessionState.id,
            conversationID: sessionState.conversationID,
            localUserID: sessionState.localUserID,
            remoteUserID: sessionState.remoteUserID,
            remoteSigningIdentityKey: sessionState.remoteSigningIdentityKey,
            remoteAgreementIdentityKey: sessionState.remoteAgreementIdentityKey,
            rootKey: sessionState.rootKey,
            sendingChainKey: chainStep.nextChainKey,
            receivingChainKey: sessionState.receivingChainKey,
            localRatchetPrivateKey: sessionState.localRatchetPrivateKey,
            remoteRatchetPublicKey: sessionState.remoteRatchetPublicKey,
            sendMessageNumber: sessionState.sendMessageNumber + 1,
            receiveMessageNumber: sessionState.receiveMessageNumber,
            previousSendingChainLength: sessionState.previousSendingChainLength,
            createdAt: sessionState.createdAt,
            updatedAt: Date(),
            needsSendRatchet: false
        )

        let headerData = try JSONEncoder().encode(header)

        return (
            ciphertext: sealedCombined.base64EncodedString(),
            header: headerData.base64EncodedString()
        )
    }

    private func bootstrapAndDecryptFirstMessage(
        envelope: CiphertextEnvelope,
        header: E2EEHeader,
        sealedCombined: Data,
        senderSigningPublicKey: Curve25519.Signing.PublicKey,
        senderIdentityKeyData: Data,
        senderIdentityAgreementKeyData: Data,
        recipientMaterial: LocalIdentityMaterial,
        recipientUserID: String
    ) throws -> DecryptedEnvelopeMessage {
        guard let senderAgreementPublicKey = try? Curve25519.KeyAgreement.PublicKey(
            rawRepresentation: senderIdentityAgreementKeyData
        ) else {
            throw E2EEError.invalidSenderIdentityAgreementKey
        }

        guard let ephemeralPublicKeyBase64 = header.ephemeralPublicKey,
              let ephemeralPublicKeyData = Data(base64Encoded: ephemeralPublicKeyBase64) else {
            throw E2EEError.invalidEphemeralPublicKey
        }

        let ephemeralPublicKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: ephemeralPublicKeyData)

        let initialRemoteRatchetPublicKey: Curve25519.KeyAgreement.PublicKey?
        if let ratchetPublicKeyBase64 = header.ratchetPublicKey {
            guard let ratchetPublicKeyData = Data(base64Encoded: ratchetPublicKeyBase64) else {
                throw E2EEError.invalidRatchetPublicKey
            }
            initialRemoteRatchetPublicKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: ratchetPublicKeyData)
        } else {
            initialRemoteRatchetPublicKey = nil
        }

        guard let signatureData = Data(base64Encoded: header.signature) else {
            throw E2EEError.invalidSignature
        }
        
        guard let signedPrekeyId = header.signedPrekeyId else {
            throw E2EEError.invalidHeader
        }

        guard let localSignedPrekey = try localKeyStore.signedPrekeyPrivateKey(
            for: recipientUserID,
            id: signedPrekeyId
        ) else {
            throw E2EEError.missingRequiredLocalSignedPrekey
        }

        let initialRootKey: Data
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
                throw E2EEError.missingRequiredLocalOneTimePrekey
            }

            let dh1 = try localSignedPrekey.sharedSecretFromKeyAgreement(with: senderAgreementPublicKey)
            let dh2 = try recipientMaterial.identityAgreementPrivateKey.sharedSecretFromKeyAgreement(with: ephemeralPublicKey)
            let dh3 = try localSignedPrekey.sharedSecretFromKeyAgreement(with: ephemeralPublicKey)
            let dh4 = try localOPK.sharedSecretFromKeyAgreement(with: ephemeralPublicKey)

            initialRootKey = deriveInitialRootKey(
                dhParts: [dh1, dh2, dh3, dh4],
                conversationID: envelope.conversationID,
                senderUserID: envelope.senderUserID,
                recipientUserID: envelope.recipientUserID,
                senderSigningIdentityKeyData: senderIdentityKeyData,
                senderAgreementIdentityKeyData: senderIdentityAgreementKeyData
            )

            consumedOneTimePrekeyId = oneTimePrekeyId

        case .fallback:
            let dh1 = try localSignedPrekey.sharedSecretFromKeyAgreement(with: ephemeralPublicKey)
            
            initialRootKey = deriveInitialRootKey(
                dhParts: [dh1],
                conversationID: envelope.conversationID,
                senderUserID: envelope.senderUserID,
                recipientUserID: envelope.recipientUserID,
                senderSigningIdentityKeyData: senderIdentityKeyData,
                senderAgreementIdentityKeyData: senderIdentityAgreementKeyData
            )

            consumedOneTimePrekeyId = nil

        case .none:
            throw E2EEError.invalidHeader
        }

        let initialSendingChain = DoubleRatchet.deriveInitialChainKey(rootKey: initialRootKey, label: "sender")
        let initialReceivingChain = DoubleRatchet.deriveInitialChainKey(rootKey: initialRootKey, label: "receiver")
        let receiveStep = DoubleRatchet.deriveChainStep(from: initialSendingChain)

        let signedContext = signingContext(
            version: header.version,
            conversationID: envelope.conversationID,
            senderUserID: envelope.senderUserID,
            recipientUserID: envelope.recipientUserID,
            senderIdentityAgreementKeyData: senderIdentityAgreementKeyData,
            ephemeralPublicKeyData: ephemeralPublicKeyData,
            ratchetPublicKeyData: initialRemoteRatchetPublicKey?.rawRepresentation ?? Data(),
            signedPrekeyId: header.signedPrekeyId,
            oneTimePrekeyId: header.oneTimePrekeyId,
            handshakeMode: header.handshakeMode,
            messageNumber: header.messageNumber,
            previousChainLength: header.previousChainLength,
            sealedCombined: sealedCombined
        )

        guard senderSigningPublicKey.isValidSignature(signatureData, for: signedContext) else {
            throw E2EEError.invalidSignature
        }

        do {
            let sealedBox = try AES.GCM.SealedBox(combined: sealedCombined)
            let plaintextData = try AES.GCM.open(sealedBox, using: receiveStep.messageKey)
            let plaintext = String(decoding: plaintextData, as: UTF8.self)

            if let oneTimePrekeyId = consumedOneTimePrekeyId {
                try localKeyStore.consumeOneTimePrekey(
                    for: recipientUserID,
                    id: oneTimePrekeyId
                )
            }

            let localRatchetPrivateKey = Curve25519.KeyAgreement.PrivateKey()

            let sessionState = RatchetSession(
                id: UUID(),
                conversationID: envelope.conversationID,
                localUserID: recipientUserID,
                remoteUserID: envelope.senderUserID,
                remoteSigningIdentityKey: header.senderIdentityKey,
                remoteAgreementIdentityKey: header.senderIdentityAgreementKey,
                rootKey: initialRootKey,
                sendingChainKey: nil,
                receivingChainKey: receiveStep.nextChainKey,
                localRatchetPrivateKey: localRatchetPrivateKey.rawRepresentation,
                remoteRatchetPublicKey: initialRemoteRatchetPublicKey?.rawRepresentation,
                sendMessageNumber: 0,
                receiveMessageNumber: 1,
                previousSendingChainLength: 0,
                createdAt: Date(),
                updatedAt: Date(),
                needsSendRatchet: true
            )

            try localSessionStore.saveSession(sessionState)

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

    private func decryptUsingExistingSession(
        envelope: CiphertextEnvelope,
        header: E2EEHeader,
        sealedCombined: Data,
        senderSigningPublicKey: Curve25519.Signing.PublicKey,
        senderIdentityKeyData: Data,
        senderIdentityAgreementKeyData: Data,
        recipientUserID: String,
        sessionState: RatchetSession
    ) throws -> DecryptedEnvelopeMessage {
        guard let signatureData = Data(base64Encoded: header.signature) else {
            throw E2EEError.invalidSignature
        }

        var mutableSession = sessionState

        let ephemeralData = Data()
        var ratchetData = Data()

        let incomingRatchetPublicKey: Curve25519.KeyAgreement.PublicKey?
        if let ratchetPublicKeyBase64 = header.ratchetPublicKey {
            guard let ratchetPublicKeyRaw = Data(base64Encoded: ratchetPublicKeyBase64) else {
                throw E2EEError.invalidRatchetPublicKey
            }
            ratchetData = ratchetPublicKeyRaw
            incomingRatchetPublicKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: ratchetPublicKeyRaw)
        } else {
            incomingRatchetPublicKey = nil
        }

        if let incomingRatchetPublicKey {
            let currentRemoteRaw = mutableSession.remoteRatchetPublicKey
            let incomingRaw = incomingRatchetPublicKey.rawRepresentation

            if currentRemoteRaw != incomingRaw {
                guard let localRatchetPrivateRaw = mutableSession.localRatchetPrivateKey else {
                    throw E2EEError.missingLocalRatchetKey
                }

                let localRatchetPrivate = try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: localRatchetPrivateRaw)
                let dh = try localRatchetPrivate.sharedSecretFromKeyAgreement(with: incomingRatchetPublicKey)

                let receiveStepRoot = DoubleRatchet.deriveRootStep(
                    rootKey: mutableSession.rootKey,
                    dhOutput: dh,
                    senderLabel: "sender",
                    receiverLabel: "receiver"
                )

                let newLocalRatchetPrivate = Curve25519.KeyAgreement.PrivateKey()

                mutableSession = RatchetSession(
                    id: mutableSession.id,
                    conversationID: mutableSession.conversationID,
                    localUserID: mutableSession.localUserID,
                    remoteUserID: mutableSession.remoteUserID,
                    remoteSigningIdentityKey: mutableSession.remoteSigningIdentityKey,
                    remoteAgreementIdentityKey: mutableSession.remoteAgreementIdentityKey,
                    rootKey: receiveStepRoot.nextRootKey,
                    sendingChainKey: nil,
                    receivingChainKey: receiveStepRoot.senderChainKey,
                    localRatchetPrivateKey: newLocalRatchetPrivate.rawRepresentation,
                    remoteRatchetPublicKey: incomingRaw,
                    sendMessageNumber: 0,
                    receiveMessageNumber: 0,
                    previousSendingChainLength: mutableSession.sendMessageNumber,
                    createdAt: mutableSession.createdAt,
                    updatedAt: Date(),
                    needsSendRatchet: true
                )
            }
        }

        let signedContext = signingContext(
            version: header.version,
            conversationID: envelope.conversationID,
            senderUserID: envelope.senderUserID,
            recipientUserID: envelope.recipientUserID,
            senderIdentityAgreementKeyData: senderIdentityAgreementKeyData,
            ephemeralPublicKeyData: ephemeralData,
            ratchetPublicKeyData: ratchetData,
            signedPrekeyId: header.signedPrekeyId,
            oneTimePrekeyId: nil,
            handshakeMode: nil,
            messageNumber: header.messageNumber,
            previousChainLength: header.previousChainLength,
            sealedCombined: sealedCombined
        )

        guard senderSigningPublicKey.isValidSignature(signatureData, for: signedContext) else {
            throw E2EEError.invalidSignature
        }

        if let plaintext = try decryptWithSkippedKeyIfAvailable(
            envelope: envelope,
            messageNumber: header.messageNumber,
            sealedCombined: sealedCombined
        ) {
            return DecryptedEnvelopeMessage(
                id: envelope.id,
                senderUserID: envelope.senderUserID,
                senderSigningIdentityKey: header.senderIdentityKey,
                senderAgreementIdentityKey: header.senderIdentityAgreementKey,
                conversationID: envelope.conversationID,
                plaintext: plaintext,
                createdAt: envelope.createdAt
            )
        }

        try cacheSkippedKeysIfNeeded(
            sessionState: &mutableSession,
            until: header.messageNumber
        )

        guard let receivingChainKey = mutableSession.receivingChainKey else {
            throw E2EEError.missingSessionBootstrapMaterial
        }

        let receiveStep = DoubleRatchet.deriveChainStep(from: receivingChainKey)

        do {
            let sealedBox = try AES.GCM.SealedBox(combined: sealedCombined)
            let plaintextData = try AES.GCM.open(sealedBox, using: receiveStep.messageKey)
            let plaintext = String(decoding: plaintextData, as: UTF8.self)

            let updatedSession = RatchetSession(
                id: mutableSession.id,
                conversationID: mutableSession.conversationID,
                localUserID: mutableSession.localUserID,
                remoteUserID: mutableSession.remoteUserID,
                remoteSigningIdentityKey: mutableSession.remoteSigningIdentityKey,
                remoteAgreementIdentityKey: mutableSession.remoteAgreementIdentityKey,
                rootKey: mutableSession.rootKey,
                sendingChainKey: mutableSession.sendingChainKey,
                receivingChainKey: receiveStep.nextChainKey,
                localRatchetPrivateKey: mutableSession.localRatchetPrivateKey,
                remoteRatchetPublicKey: mutableSession.remoteRatchetPublicKey,
                sendMessageNumber: mutableSession.sendMessageNumber,
                receiveMessageNumber: header.messageNumber + 1,
                previousSendingChainLength: mutableSession.previousSendingChainLength,
                createdAt: mutableSession.createdAt,
                updatedAt: Date(),
                needsSendRatchet: mutableSession.needsSendRatchet
            )

            try localSessionStore.saveSession(updatedSession)

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

        let signaturePayload = localKeyStore.signedPrekeySignaturePayload(
            signedPrekeyID: bundle.signedPrekeyId,
            signedPrekeyPublicKey: signedPrekeyData
        )

        guard signingIdentityPublicKey.isValidSignature(signatureData, for: signaturePayload) else {
            throw E2EEError.invalidRecipientSignedPrekeySignature
        }
    }

    private func deriveInitialRootKey(
        dhParts: [SharedSecret],
        conversationID: UUID,
        senderUserID: String,
        recipientUserID: String,
        senderSigningIdentityKeyData: Data,
        senderAgreementIdentityKeyData: Data
    ) -> Data {
        var ikm = Data()
        for part in dhParts {
            ikm.append(part.withUnsafeBytes { Data($0) })
        }

        let inputKeyMaterial = SymmetricKey(data: ikm)

        let key = HKDF<SHA256>.deriveKey(
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

        return key.withUnsafeBytes { Data($0) }
    }

    private func currentUserID() async throws -> String {
        let current = await MainActor.run { session.currentUserID }
        guard let current, !current.isEmpty else {
            throw E2EEError.noAuthenticatedUser
        }
        return current
    }

    private var protocolSalt: Data {
        Data("VilLovChat-E2EE-v5".utf8)
    }

    private func sharedInfo(
        conversationID: UUID,
        senderUserID: String,
        recipientUserID: String,
        senderSigningIdentityKeyData: Data,
        senderAgreementIdentityKeyData: Data
    ) -> Data {
        var data = Data()
        data.append(Data("VilLovChat-X3DH-Root-v5".utf8))
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
        ratchetPublicKeyData: Data,
        signedPrekeyId: String?,
        oneTimePrekeyId: String?,
        handshakeMode: HandshakeMode?,
        messageNumber: Int,
        previousChainLength: Int,
        sealedCombined: Data
    ) -> Data {
        var data = Data()
        data.append(Data("VilLovChat-E2EE-sign-v5".utf8))
        data.append(Data(String(version).utf8))
        data.append(Data(conversationID.uuidString.utf8))
        data.append(Data(senderUserID.utf8))
        data.append(Data(recipientUserID.utf8))
        data.append(senderIdentityAgreementKeyData)
        data.append(ephemeralPublicKeyData)
        data.append(ratchetPublicKeyData)
        data.append(Data((signedPrekeyId ?? "").utf8))
        data.append(Data((oneTimePrekeyId ?? "").utf8))
        data.append(Data((handshakeMode?.rawValue ?? "").utf8))
        data.append(Data(String(messageNumber).utf8))
        data.append(Data(String(previousChainLength).utf8))
        data.append(sealedCombined)
        return data
    }
    
    private func performPendingSendRatchetIfNeeded(
        sessionState: inout RatchetSession
    ) throws {
        guard sessionState.needsSendRatchet else { return }

        guard let localRatchetPrivateRaw = sessionState.localRatchetPrivateKey else {
            throw E2EEError.missingLocalRatchetKey
        }

        guard let remoteRatchetPublicRaw = sessionState.remoteRatchetPublicKey else {
            throw E2EEError.invalidRatchetPublicKey
        }

        let localRatchetPrivate = try Curve25519.KeyAgreement.PrivateKey(
            rawRepresentation: localRatchetPrivateRaw
        )

        let remoteRatchetPublic = try Curve25519.KeyAgreement.PublicKey(
            rawRepresentation: remoteRatchetPublicRaw
        )

        let dh = try localRatchetPrivate.sharedSecretFromKeyAgreement(with: remoteRatchetPublic)

        let sendStepRoot = DoubleRatchet.deriveRootStep(
            rootKey: sessionState.rootKey,
            dhOutput: dh,
            senderLabel: "sender",
            receiverLabel: "receiver"
        )

        sessionState = RatchetSession(
            id: sessionState.id,
            conversationID: sessionState.conversationID,
            localUserID: sessionState.localUserID,
            remoteUserID: sessionState.remoteUserID,
            remoteSigningIdentityKey: sessionState.remoteSigningIdentityKey,
            remoteAgreementIdentityKey: sessionState.remoteAgreementIdentityKey,
            rootKey: sendStepRoot.nextRootKey,
            sendingChainKey: sendStepRoot.senderChainKey,
            receivingChainKey: sessionState.receivingChainKey,
            localRatchetPrivateKey: sessionState.localRatchetPrivateKey,
            remoteRatchetPublicKey: sessionState.remoteRatchetPublicKey,
            sendMessageNumber: 0,
            receiveMessageNumber: sessionState.receiveMessageNumber,
            previousSendingChainLength: sessionState.previousSendingChainLength,
            createdAt: sessionState.createdAt,
            updatedAt: Date(),
            needsSendRatchet: false
        )
    }
    
    private func symmetricKeyData(_ key: SymmetricKey) -> Data {
        key.withUnsafeBytes { Data($0) }
    }

    private func decryptWithSkippedKeyIfAvailable(
        envelope: CiphertextEnvelope,
        messageNumber: Int,
        sealedCombined: Data
    ) throws -> String? {
        guard let skipped = try localSkippedKeyStore.takeKey(
            conversationID: envelope.conversationID,
            localUserID: envelope.recipientUserID,
            remoteUserID: envelope.senderUserID,
            messageNumber: messageNumber
        ) else {
            return nil
        }

        let sealedBox = try AES.GCM.SealedBox(combined: sealedCombined)
        let plaintextData = try AES.GCM.open(
            sealedBox,
            using: SymmetricKey(data: skipped.keyData)
        )
        return String(decoding: plaintextData, as: UTF8.self)
    }

    private func cacheSkippedKeysIfNeeded(
        sessionState: inout RatchetSession,
        until incomingMessageNumber: Int
    ) throws {
        guard let receivingChainKey = sessionState.receivingChainKey else {
            throw E2EEError.missingSessionBootstrapMaterial
        }

        let current = sessionState.receiveMessageNumber
        guard incomingMessageNumber > current else { return }

        let distance = incomingMessageNumber - current
        guard distance <= maxSkipWindow else {
            throw E2EEError.decryptionFailed
        }

        var chainKey = receivingChainKey
        var index = current

        while index < incomingMessageNumber {
            let step = DoubleRatchet.deriveChainStep(from: chainKey)
            let skipped = SkippedMessageKey(
                conversationID: sessionState.conversationID,
                localUserID: sessionState.localUserID,
                remoteUserID: sessionState.remoteUserID,
                messageNumber: index,
                keyData: symmetricKeyData(step.messageKey)
            )
            try localSkippedKeyStore.store(skipped)
            chainKey = step.nextChainKey
            index += 1
        }

        sessionState = RatchetSession(
            id: sessionState.id,
            conversationID: sessionState.conversationID,
            localUserID: sessionState.localUserID,
            remoteUserID: sessionState.remoteUserID,
            remoteSigningIdentityKey: sessionState.remoteSigningIdentityKey,
            remoteAgreementIdentityKey: sessionState.remoteAgreementIdentityKey,
            rootKey: sessionState.rootKey,
            sendingChainKey: sessionState.sendingChainKey,
            receivingChainKey: chainKey,
            localRatchetPrivateKey: sessionState.localRatchetPrivateKey,
            remoteRatchetPublicKey: sessionState.remoteRatchetPublicKey,
            sendMessageNumber: sessionState.sendMessageNumber,
            receiveMessageNumber: incomingMessageNumber,
            previousSendingChainLength: sessionState.previousSendingChainLength,
            createdAt: sessionState.createdAt,
            updatedAt: Date(),
            needsSendRatchet: sessionState.needsSendRatchet
        )
    }
    
    private func deterministicConversationID(localUserID: String, remoteUserID: String) -> UUID {
        let sorted = [localUserID, remoteUserID].sorted().joined(separator: ":")
        let digest = SHA256.hash(data: Data(sorted.utf8))
        let data = Data(digest.prefix(16))
        let uuid = data.withUnsafeBytes { raw -> UUID in
            let bytes = raw.bindMemory(to: UInt8.self)
            return UUID(uuid: (
                bytes[0], bytes[1], bytes[2], bytes[3],
                bytes[4], bytes[5], bytes[6], bytes[7],
                bytes[8], bytes[9], bytes[10], bytes[11],
                bytes[12], bytes[13], bytes[14], bytes[15]
            ))
        }
        return uuid
    }
}
