//
//  Message.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//

import Foundation

struct Message: Identifiable {
    let id: UUID
    let text: String
    let isIncoming: Bool
    let timestamp: Date
    let status: MessageStatus
}

enum MessageStatus {
    case sending
    case sent
    case delivered
    case read
    case failed
}
