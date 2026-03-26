//
//  Conversation+Mock.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//

import Foundation

private let aliceBobConversationID = UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!
private let aliceCharlieConversationID = UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!

extension Conversation {
    static let aliceViewOfBob = Conversation(
        id: aliceBobConversationID,
        title: "Bob Smith",
        lastMessagePreview: "Latest message with Bob",
        lastActivity: Date(),
        unreadCount: 0,
        trustState: .unverified,
        disappearingEnabled: false,
        recipientUserID: "user_bob"
    )

    static let bobViewOfAlice = Conversation(
        id: aliceBobConversationID,
        title: "Alice Johnson",
        lastMessagePreview: "Latest message with Alice",
        lastActivity: Date(),
        unreadCount: 0,
        trustState: .verified,
        disappearingEnabled: true,
        recipientUserID: "user_alice"
    )

    static let aliceViewOfCharlie = Conversation(
        id: aliceCharlieConversationID,
        title: "Charlie Brown",
        lastMessagePreview: "Latest message with Charlie",
        lastActivity: Date(),
        unreadCount: 0,
        trustState: .verified,
        disappearingEnabled: false,
        recipientUserID: "user_charlie"
    )

    static let charlieViewOfAlice = Conversation(
        id: aliceCharlieConversationID,
        title: "Alice Johnson",
        lastMessagePreview: "Latest message with Alice",
        lastActivity: Date(),
        unreadCount: 0,
        trustState: .verified,
        disappearingEnabled: false,
        recipientUserID: "user_alice"
    )
}
