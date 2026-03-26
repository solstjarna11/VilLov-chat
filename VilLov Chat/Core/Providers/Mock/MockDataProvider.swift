//
//  MockDataProvider.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//


import Foundation

struct MockDataProvider: ConversationProviding, ContactProviding, DeviceProviding, MessageProviding {
    func loadConversations(for currentUserID: String?) -> [Conversation] {
        switch currentUserID {
        case "user_alice":
            return [
                .aliceViewOfBob,
                .aliceViewOfCharlie
            ]
        case "user_bob":
            return [
                .bobViewOfAlice
            ]
        case "user_charlie":
            return [
                .charlieViewOfAlice
            ]
        default:
            return []
        }
    }

    func loadContacts(for currentUserID: String?) -> [Contact] {
        switch currentUserID {
        case "user_alice":
            return [
                .mockBob,
                .mockCharlie
            ]
        case "user_bob":
            return [
                .mockAlice
            ]
        case "user_charlie":
            return [
                .mockAlice
            ]
        default:
            return []
        }
    }

    func loadDevices() -> [Device] {
        Device.mockData
    }

    func loadMessages(for conversation: Conversation) -> [Message] {
        Message.mockMessages
    }
}
