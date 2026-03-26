//
//  ConversationServicing.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 26.3.2026.
//


import Foundation

protocol ConversationServicing {
    func sendMessage(
        plaintext: String,
        to recipientUserID: String,
        conversationID: UUID
    ) async throws

    func fetchInbox() async throws -> [DecryptedEnvelopeMessage]
}