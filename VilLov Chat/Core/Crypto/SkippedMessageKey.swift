//
//  SkippedMessageKey.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 19.4.2026.
//


import Foundation

struct SkippedMessageKey: Codable, Equatable, Identifiable {
    let id: String
    let conversationID: UUID
    let localUserID: String
    let remoteUserID: String
    let messageNumber: Int
    let keyData: Data
    let createdAt: Date

    init(
        conversationID: UUID,
        localUserID: String,
        remoteUserID: String,
        messageNumber: Int,
        keyData: Data,
        createdAt: Date = Date()
    ) {
        self.id = "\(conversationID.uuidString):\(localUserID):\(remoteUserID):\(messageNumber)"
        self.conversationID = conversationID
        self.localUserID = localUserID
        self.remoteUserID = remoteUserID
        self.messageNumber = messageNumber
        self.keyData = keyData
        self.createdAt = createdAt
    }
}