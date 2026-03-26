//
//  ConversationService.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 26.3.2026.
//
// This is the first real orchestration layer.

import Foundation

final class ConversationService: ConversationServicing {
    private let keyDirectoryService: KeyDirectoryService
    private let relayService: RelayService
    private let e2eeEngine: E2EEEngine

    init(
        keyDirectoryService: KeyDirectoryService,
        relayService: RelayService,
        e2eeEngine: E2EEEngine
    ) {
        self.keyDirectoryService = keyDirectoryService
        self.relayService = relayService
        self.e2eeEngine = e2eeEngine
    }

    func sendMessage(
        plaintext: String,
        to recipientUserID: String,
        conversationID: UUID
    ) async throws {
        print("ConversationService.sendMessage started for recipient:", recipientUserID)

        let keyBundle = try await keyDirectoryService.fetchRecipientKeyBundle(for: recipientUserID)
        print("Fetched key bundle for:", keyBundle.userID)

        try await e2eeEngine.ensureSession(
            with: recipientUserID,
            bundle: keyBundle
        )
        print("Ensured session for recipient:", recipientUserID)

        let encrypted = try await e2eeEngine.encrypt(
            plaintext: plaintext,
            recipientUserID: recipientUserID,
            conversationID: conversationID
        )
        print("Encrypted message for conversation:", conversationID.uuidString)

        let request = SendCiphertextRequest(
            recipientUserID: recipientUserID,
            messageID: UUID(),
            conversationID: conversationID,
            ciphertext: encrypted.ciphertext,
            header: encrypted.header,
            sentAt: Date()
        )

        try await relayService.send(request)
        print("Sent ciphertext envelope to backend for recipient:", recipientUserID)
    }

    func fetchInbox() async throws -> [DecryptedEnvelopeMessage] {
        print("ConversationService.fetchInbox started")

        let envelopes = try await relayService.fetchInbox()
        print("Fetched inbox envelopes count:", envelopes.count)

        var decryptedMessages: [DecryptedEnvelopeMessage] = []

        for envelope in envelopes {
            let decrypted = try await e2eeEngine.decrypt(envelope: envelope)
            decryptedMessages.append(decrypted)
            try await relayService.acknowledge(messageID: envelope.id)
            print("Acknowledged message:", envelope.id.uuidString)
        }

        return decryptedMessages.sorted { $0.createdAt < $1.createdAt }
    }
}
