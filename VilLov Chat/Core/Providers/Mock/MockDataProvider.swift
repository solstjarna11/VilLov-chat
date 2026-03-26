//
//  MockDataProvider.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//


import Foundation

struct MockDataProvider: ConversationProviding, ContactProviding, DeviceProviding, MessageProviding {
    func loadConversations() -> [Conversation] {
        Conversation.mockData
    }

    func loadContacts() -> [Contact] {
        Contact.mockData
    }

    func loadDevices() -> [Device] {
        Device.mockData
    }

    func loadMessages(for conversation: Conversation) -> [Message] {
        Message.mockMessages
    }
}