//
//  Conversation+Mapping.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 12.4.2026.
//


import Foundation

extension Conversation {
    static func from(
        api: APIConversation,
        currentUserID: String,
        contactsByUserID: [String: Contact]
    ) -> Conversation {
        let otherUserID =
            api.participantAUserID == currentUserID
            ? api.participantBUserID
            : api.participantAUserID

        let contact = contactsByUserID[otherUserID]

        return Conversation(
            id: api.conversationID,
            title: contact?.name ?? otherUserID,
            lastMessagePreview: "",
            lastActivity: api.createdAt,
            unreadCount: 0,
            trustState: contact?.trustState ?? .unverified,
            disappearingEnabled: false,
            recipientUserID: otherUserID
        )
    }
}
