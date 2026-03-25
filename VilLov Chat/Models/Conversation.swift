//
//  Conversation.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//

import Foundation

struct Conversation: Identifiable, Hashable {
    let id: UUID
    let title: String
    let lastMessagePreview: String
    let lastActivity: Date
    let unreadCount: Int
    let trustState: ContactTrustState

    var isVerified: Bool {
        trustState == .verified
    }
    let disappearingEnabled: Bool
}
