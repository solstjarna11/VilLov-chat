//
//  StubE2EEEngine.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 26.3.2026.
//
// This is only for wiring. It is not real encryption.

import Foundation

final class StubE2EEEngine: E2EEEngine {
    func ensureSession(
        with recipientUserID: String,
        bundle: RecipientKeyBundle
    ) async throws {
        // Stub: no-op for now.
    }

    func encrypt(
        plaintext: String,
        recipientUserID: String,
        conversationID: UUID
    ) async throws -> (ciphertext: String, header: String) {
        let ciphertext = Data(plaintext.utf8).base64EncodedString()
        let header = "stub-header"
        return (ciphertext, header)
    }

    func decrypt(
        envelope: CiphertextEnvelope
    ) async throws -> DecryptedEnvelopeMessage {
        let plaintextData = Data(base64Encoded: envelope.ciphertext) ?? Data()
        let plaintext = String(decoding: plaintextData, as: UTF8.self)

        return DecryptedEnvelopeMessage(
            id: envelope.id,
            senderUserID: envelope.senderUserID,
            conversationID: envelope.conversationID,
            plaintext: plaintext,
            createdAt: envelope.createdAt
        )
    }
}
