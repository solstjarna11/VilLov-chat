//
//  ChatViewModel.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//


import Foundation
import SwiftUI
import Combine

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messageText = ""
    @Published private(set) var messages: [Message]

    let conversation: Conversation

    init(
        conversation: Conversation,
        messages: [Message]? = nil
    ) {
        self.conversation = conversation
        self.messages = messages ?? Message.mockMessages
    }

    var trimmedMessageText: String {
        messageText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canSendMessage: Bool {
        !trimmedMessageText.isEmpty
    }

    func sendMessage() {
        guard canSendMessage else { return }

        let newMessage = Message(
            id: UUID(),
            text: trimmedMessageText,
            isIncoming: false,
            timestamp: Date(),
            status: .sending
        )

        messages.append(newMessage)
        messageText = ""
    }
}
