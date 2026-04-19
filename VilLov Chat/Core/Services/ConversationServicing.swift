//
//  ConversationServicing.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 26.3.2026.
//


import Foundation

struct InboxRefreshResult {
    let messages: [DecryptedEnvelopeMessage]
    let failures: [InboxMessageFailure]
}

struct InboxMessageFailure: Identifiable, Equatable {
    let id: UUID
    let envelopeID: UUID
    let senderUserID: String
    let conversationID: UUID
    let reason: String
    let createdAt: Date
}

protocol ConversationServicing {
    func sendMessage(
        plaintext: String,
        to recipientUserID: String,
        conversationID: UUID
    ) async throws

    func fetchInbox() async throws -> [DecryptedEnvelopeMessage]

    func fetchInboxResilient() async throws -> InboxRefreshResult

    func getOrCreateConversation(with recipientUserID: String) async throws -> UUID
}
