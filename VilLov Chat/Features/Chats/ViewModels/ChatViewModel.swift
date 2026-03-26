//
//  ChatViewModel.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//


import Foundation
import Observation

@MainActor
@Observable
final class ChatViewModel {
    var messageText = ""
    private(set) var messages: [Message]

    let conversation: Conversation

    private let provider: MessageProviding

    init(
        conversation: Conversation,
        provider: MessageProviding
    ) {
        self.conversation = conversation
        self.provider = provider
        self.messages = provider.loadMessages(for: conversation)
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
