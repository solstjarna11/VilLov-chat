//
//  E2EEEngine.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 26.3.2026.
//


import Foundation

struct DecryptedEnvelopeMessage: Equatable, Identifiable {
    let id: UUID
    let senderUserID: String
    let senderSigningIdentityKey: String
    let senderAgreementIdentityKey: String
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
        recipientBundle: RecipientKeyBundle,
        conversationID: UUID
    ) async throws -> (ciphertext: String, header: String)

    func decrypt(
        envelope: CiphertextEnvelope
    ) async throws -> DecryptedEnvelopeMessage
}
