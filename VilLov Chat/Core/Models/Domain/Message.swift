//
//  Message.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//

import Foundation

enum MessageVisibility: String, Codable, Hashable {
    case visible
    case hidden
}

struct Message: Identifiable, Hashable {
    let id: UUID
    let text: String
    let isIncoming: Bool
    let timestamp: Date
    let status: MessageStatus
    let visibility: MessageVisibility
}

enum MessageStatus: String, Codable {
    case sending
    case sent
    case delivered
    case read
    case failed
}
