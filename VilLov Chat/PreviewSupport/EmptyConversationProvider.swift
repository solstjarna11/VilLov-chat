//
//  EmptyConversationProvider.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 26.3.2026.
//


import Foundation

struct EmptyConversationProvider: ConversationProviding {
    func loadConversations(for currentUserId: String?) -> [Conversation] {
        []
    }
}

struct PopulatedConversationProvider: ConversationProviding {
    func loadConversations(for currentUserId: String?) -> [Conversation] {
        [
            Conversation(
                id: UUID(),
                title: "Alice Johnson",
                lastMessagePreview: "I reviewed the latest security notes.",
                lastActivity: Date(),
                unreadCount: 2,
                trustState: .verified,
                disappearingEnabled: true
            ),
            Conversation(
                id: UUID(),
                title: "Bob Smith",
                lastMessagePreview: "Let’s finalize device linking tomorrow.",
                lastActivity: Date().addingTimeInterval(-3600),
                unreadCount: 0,
                trustState: .unverified,
                disappearingEnabled: false
            ),
            Conversation(
                id: UUID(),
                title: "Project Team",
                lastMessagePreview: "The updated architecture diagram looks good.",
                lastActivity: Date().addingTimeInterval(-7200),
                unreadCount: 5,
                trustState: .verified,
                disappearingEnabled: false
            )
        ]
    }
}
