//
//  PreviewConversationService.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 26.3.2026.
//


import Foundation

struct PreviewConversationService: ConversationServicing {
    func sendMessage(
        plaintext: String,
        to recipientUserID: String,
        conversationID: UUID
    ) async throws {
        // Preview stub: no-op
    }

    func fetchInbox() async throws -> [DecryptedEnvelopeMessage] {
        []
    }
}