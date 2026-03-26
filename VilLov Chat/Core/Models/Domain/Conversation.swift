//
//  Conversation.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//

import Foundation

struct Conversation: Identifiable, Equatable, Hashable {
    let id: UUID
    let title: String
    let lastMessagePreview: String
    let lastActivity: Date
    let unreadCount: Int
    let trustState: ContactTrustState
    let disappearingEnabled: Bool
    let recipientUserID: String?

    init(
        id: UUID,
        title: String,
        lastMessagePreview: String,
        lastActivity: Date,
        unreadCount: Int,
        trustState: ContactTrustState,
        disappearingEnabled: Bool,
        recipientUserID: String? = nil
    ) {
        self.id = id
        self.title = title
        self.lastMessagePreview = lastMessagePreview
        self.lastActivity = lastActivity
        self.unreadCount = unreadCount
        self.trustState = trustState
        self.disappearingEnabled = disappearingEnabled
        self.recipientUserID = recipientUserID
    }

    var isVerified: Bool {
        trustState == .verified
    }
}
