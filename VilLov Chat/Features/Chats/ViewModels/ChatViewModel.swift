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
    var errorMessage: String?
    var isSending = false
    var isRefreshingInbox = false
    private(set) var messages: [Message]

    let conversation: Conversation

    private let messageProvider: MessageProviding
    private let conversationService: ConversationServicing?

    init(
        conversation: Conversation,
        provider: MessageProviding,
        conversationService: ConversationServicing? = nil
    ) {
        self.conversation = conversation
        self.messageProvider = provider
        self.conversationService = conversationService
        self.messages = provider.loadMessages(for: conversation)
    }

    var trimmedMessageText: String {
        messageText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canSendMessage: Bool {
        !trimmedMessageText.isEmpty && !isSending
    }

    func sendMessage() {
        guard canSendMessage else { return }

        let outgoingText = trimmedMessageText

        let optimisticMessage = Message(
            id: UUID(),
            text: outgoingText,
            isIncoming: false,
            timestamp: Date(),
            status: .sending
        )

        messages.append(optimisticMessage)
        messageText = ""
        errorMessage = nil

        guard
            let conversationService,
            let recipientUserID = conversation.recipientUserID
        else {
            markMessageAsSent(optimisticMessage.id)
            return
        }

        isSending = true

        Task {
            do {
                try await conversationService.sendMessage(
                    plaintext: outgoingText,
                    to: recipientUserID,
                    conversationID: conversation.id
                )

                await MainActor.run {
                    self.markMessageAsSent(optimisticMessage.id)
                    self.isSending = false
                }
            } catch {
                await MainActor.run {
                    self.markMessageAsFailed(optimisticMessage.id)
                    self.errorMessage = error.localizedDescription
                    self.isSending = false
                }
            }
        }
    }

    func refreshInbox() {
        guard let conversationService else { return }

        errorMessage = nil
        isRefreshingInbox = true

        Task {
            do {
                let inboxMessages = try await conversationService.fetchInbox()

                await MainActor.run {
                    self.mergeInboxMessages(inboxMessages)
                    self.isRefreshingInbox = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isRefreshingInbox = false
                }
            }
        }
    }

    private func mergeInboxMessages(_ inboxMessages: [DecryptedEnvelopeMessage]) {
        let matchingConversationMessages = inboxMessages.filter {
            $0.conversationID == conversation.id
        }

        let newMessages = matchingConversationMessages.map { decrypted in
            Message(
                id: decrypted.id,
                text: decrypted.plaintext,
                isIncoming: true,
                timestamp: decrypted.createdAt,
                status: .sent
            )
        }

        for newMessage in newMessages {
            guard !messages.contains(where: { $0.id == newMessage.id }) else { continue }
            messages.append(newMessage)
        }

        messages.sort { $0.timestamp < $1.timestamp }
    }

    private func markMessageAsSent(_ id: UUID) {
        guard let index = messages.firstIndex(where: { $0.id == id }) else { return }
        let old = messages[index]
        messages[index] = Message(
            id: old.id,
            text: old.text,
            isIncoming: old.isIncoming,
            timestamp: old.timestamp,
            status: .sent
        )
    }

    private func markMessageAsFailed(_ id: UUID) {
        guard let index = messages.firstIndex(where: { $0.id == id }) else { return }
        let old = messages[index]
        messages[index] = Message(
            id: old.id,
            text: old.text,
            isIncoming: old.isIncoming,
            timestamp: old.timestamp,
            status: .failed
        )
    }
}
