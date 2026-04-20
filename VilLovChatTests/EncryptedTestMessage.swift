//
//  EncryptedTestMessage.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 19.4.2026.
//


import Foundation
import Testing
import CryptoKit

@testable import VilLov_Chat

struct EncryptedTestMessage {
    let ciphertext: String
    let header: String
    let envelope: CiphertextEnvelope
}

@MainActor
final class TestClient {
    let userID: String

    let tokenStore: AuthTokenStore
    let appSession: AppSession

    let localKeyStore: LocalKeyStore
    let localSessionStore: LocalSessionStore
    let localSkippedKeyStore: LocalSkippedKeyStore

    let e2eeEngine: DefaultE2EEEngine

    init(
        userID: String,
        localKeyStore: LocalKeyStore,
        localSessionStore: LocalSessionStore,
        localSkippedKeyStore: LocalSkippedKeyStore
    ) {
        self.userID = userID
        self.tokenStore = AuthTokenStore()
        self.appSession = AppSession(tokenStore: tokenStore)
        self.localKeyStore = localKeyStore
        self.localSessionStore = localSessionStore
        self.localSkippedKeyStore = localSkippedKeyStore

        self.appSession.completeAuthentication(
            userID: userID,
            rememberedAccountName: userID,
            isPasskeyConfigured: true
        )

        self.e2eeEngine = DefaultE2EEEngine(
            localKeyStore: localKeyStore,
            localSessionStore: localSessionStore,
            localSkippedKeyStore: localSkippedKeyStore,
            session: appSession
        )
    }

    static func make(
        userID: String,
        encryptedStoreFactory: (() -> EncryptedFileStore)? = nil
    ) -> TestClient {
        let localKeyStore = LocalKeyStore()

        let encryptedStore1 = encryptedStoreFactory?() ?? EncryptedFileStore()
        let encryptedStore2 = encryptedStoreFactory?() ?? EncryptedFileStore()

        let localSessionStore = LocalSessionStore(encryptedStore: encryptedStore1)
        let localSkippedKeyStore = LocalSkippedKeyStore(encryptedStore: encryptedStore2)

        return TestClient(
            userID: userID,
            localKeyStore: localKeyStore,
            localSessionStore: localSessionStore,
            localSkippedKeyStore: localSkippedKeyStore
        )
    }

    static func makePair() -> (TestClient, TestClient) {
        let alice = make(userID: "alice")
        let bob = make(userID: "bob")
        return (alice, bob)
    }

    func recipientBundle(oneTimePrekeyCount: Int = 20) throws -> RecipientKeyBundle {
        let upload = try localKeyStore.uploadBundleRequest(
            for: userID,
            oneTimePrekeyCount: oneTimePrekeyCount
        )

        let oneTime = upload.oneTimePrekeys.first

        return RecipientKeyBundle(
            userID: upload.userID,
            identityKey: upload.identityKey,
            identityAgreementKey: upload.identityAgreementKey,
            signedPrekeyId: upload.signedPrekeyId,
            signedPrekey: upload.signedPrekey,
            signedPrekeySignature: upload.signedPrekeySignature,
            oneTimePrekey: oneTime?.publicKey,
            oneTimePrekeyId: oneTime?.id
        )
    }

    func ensureSession(with recipient: TestClient, conversationID: UUID) async throws {
        let bundle = try recipient.recipientBundle()
        try await e2eeEngine.ensureSession(
            with: recipient.userID,
            bundle: bundle
        )

        _ = conversationID
    }

    func send(
        _ plaintext: String,
        to recipient: TestClient,
        conversationID: UUID
    ) async throws -> EncryptedTestMessage {
        let bundle = try recipient.recipientBundle()

        let encrypted = try await e2eeEngine.encrypt(
            plaintext: plaintext,
            recipientBundle: bundle,
            conversationID: conversationID
        )

        let envelope = CiphertextEnvelope(
            id: UUID(),
            senderUserID: userID,
            recipientUserID: recipient.userID,
            conversationID: conversationID,
            ciphertext: encrypted.ciphertext,
            header: encrypted.header,
            createdAt: Date()
        )

        return EncryptedTestMessage(
            ciphertext: encrypted.ciphertext,
            header: encrypted.header,
            envelope: envelope
        )
    }

    func receive(_ message: EncryptedTestMessage) async throws -> String {
        let decrypted = try await e2eeEngine.decrypt(envelope: message.envelope)
        return decrypted.plaintext
    }

    func reload(
        encryptedStoreFactory: (() -> EncryptedFileStore)? = nil
    ) -> TestClient {
        // Reuse same key/session/skipped stores if we want true persistence simulation.
        // Since LocalKeyStore is Keychain-backed and session/skipped stores are injected,
        // this method reconstructs only the engine/session wrapper.

        TestClient(
            userID: userID,
            localKeyStore: localKeyStore,
            localSessionStore: localSessionStore,
            localSkippedKeyStore: localSkippedKeyStore
        )
    }
    
    func rotateSignedPrekey() throws {
        _ = try localKeyStore.rotateSignedPrekey(for: userID)
    }

    func purgeRetiredSignedPrekeys(olderThan cutoff: Date) throws {
        try localKeyStore.purgeRetiredSignedPrekeys(for: userID, olderThan: cutoff)
    }

    func tamperedRecipientBundleChangingSignedPrekeyId(
        oneTimePrekeyCount: Int = 20
    ) throws -> RecipientKeyBundle {
        let bundle = try recipientBundle(oneTimePrekeyCount: oneTimePrekeyCount)

        return RecipientKeyBundle(
            userID: bundle.userID,
            identityKey: bundle.identityKey,
            identityAgreementKey: bundle.identityAgreementKey,
            signedPrekeyId: UUID().uuidString.lowercased(), // tampered, signature unchanged
            signedPrekey: bundle.signedPrekey,
            signedPrekeySignature: bundle.signedPrekeySignature,
            oneTimePrekey: bundle.oneTimePrekey,
            oneTimePrekeyId: bundle.oneTimePrekeyId
        )
    }

    func tamperedRecipientBundleChangingSignedPrekey(
        oneTimePrekeyCount: Int = 20
    ) throws -> RecipientKeyBundle {
        let bundle = try recipientBundle(oneTimePrekeyCount: oneTimePrekeyCount)

        guard let signedPrekeyData = Data(base64Encoded: bundle.signedPrekey), !signedPrekeyData.isEmpty else {
            return bundle
        }

        var tampered = signedPrekeyData
        tampered[tampered.startIndex] ^= 0x01

        return RecipientKeyBundle(
            userID: bundle.userID,
            identityKey: bundle.identityKey,
            identityAgreementKey: bundle.identityAgreementKey,
            signedPrekeyId: bundle.signedPrekeyId,
            signedPrekey: tampered.base64EncodedString(),
            signedPrekeySignature: bundle.signedPrekeySignature,
            oneTimePrekey: bundle.oneTimePrekey,
            oneTimePrekeyId: bundle.oneTimePrekeyId
        )
    }

    func send(
        _ plaintext: String,
        to recipient: TestClient,
        using recipientBundle: RecipientKeyBundle,
        conversationID: UUID
    ) async throws -> EncryptedTestMessage {
        let encrypted = try await e2eeEngine.encrypt(
            plaintext: plaintext,
            recipientBundle: recipientBundle,
            conversationID: conversationID
        )

        let envelope = CiphertextEnvelope(
            id: UUID(),
            senderUserID: userID,
            recipientUserID: recipient.userID,
            conversationID: conversationID,
            ciphertext: encrypted.ciphertext,
            header: encrypted.header,
            createdAt: Date()
        )

        return EncryptedTestMessage(
            ciphertext: encrypted.ciphertext,
            header: encrypted.header,
            envelope: envelope
        )
    }
}

enum TestConversationIDs {
    static func deterministic(_ a: String, _ b: String) -> UUID {
        let sorted = [a, b].sorted().joined(separator: ":")
        let digest = SHA256.hash(data: Data(sorted.utf8))
        let data = Data(digest.prefix(16))

        return data.withUnsafeBytes { raw -> UUID in
            let bytes = raw.bindMemory(to: UInt8.self)
            return UUID(uuid: (
                bytes[0], bytes[1], bytes[2], bytes[3],
                bytes[4], bytes[5], bytes[6], bytes[7],
                bytes[8], bytes[9], bytes[10], bytes[11],
                bytes[12], bytes[13], bytes[14], bytes[15]
            ))
        }
    }
}
