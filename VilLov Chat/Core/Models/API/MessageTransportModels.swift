//
//  SendCiphertextRequest.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 26.3.2026.
//


import Foundation

struct SendCiphertextRequest: Codable, Equatable {
    let recipientUserID: String
    let messageID: UUID
    let conversationID: UUID
    let ciphertext: String
    let header: String
    let sentAt: Date
}

struct MessageAckRequest: Codable, Equatable {
    let messageID: UUID
}

struct CiphertextEnvelope: Codable, Identifiable, Equatable {
    let id: UUID
    let senderUserID: String
    let recipientUserID: String
    let conversationID: UUID
    let ciphertext: String
    let header: String
    let createdAt: Date
}