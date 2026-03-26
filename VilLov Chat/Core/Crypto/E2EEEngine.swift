//
//  E2EEEngine.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 26.3.2026.
//
// Start with a protocol. Real crypto can come later.

import Foundation

struct DecryptedEnvelopeMessage: Equatable, Identifiable {
    let id: UUID
    let senderUserID: String
    let conversationID: UUID
    let plaintext: String
    let createdAt: Date
}

protocol E2EEEngine {
    func ensureSession(
        with recipientUserID: String,
        bundle: RecipientKeyBundle
    ) async throws

    func encrypt(
        plaintext: String,
        recipientUserID: String,
        conversationID: UUID
    ) async throws -> (ciphertext: String, header: String)

    func decrypt(
        envelope: CiphertextEnvelope
    ) async throws -> DecryptedEnvelopeMessage
}
