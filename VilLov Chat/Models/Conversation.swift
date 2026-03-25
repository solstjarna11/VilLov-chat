//
//  Conversation.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//

import Foundation

struct Conversation: Identifiable {
    let id: UUID
    let title: String
    let lastMessagePreview: String
    let lastActivity: Date
    let unreadCount: Int
    let isVerified: Bool
    let disappearingEnabled: Bool
}
