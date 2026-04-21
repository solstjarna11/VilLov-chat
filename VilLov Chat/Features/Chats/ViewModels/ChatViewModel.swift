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

    let currentUserID: String
    private let messageProvider: MessageProviding
    private let conversationService: ConversationServicing?
    private let localMessageStore: LocalMessageStore

    private let failedDecryptPlaceholderText = "Message could not be decrypted."

    init(
        conversation: Conversation,
        currentUserID: String,
        provider: MessageProviding,
        conversationService: ConversationServicing? = nil,
        localMessageStore: LocalMessageStore? = nil
    ) {
        self.conversation = conversation
        self.currentUserID = currentUserID
        self.messageProvider = provider
        self.conversationService = conversationService
        self.localMessageStore = localMessageStore ?? LocalMessageStore()

        if conversationService == nil {
            self.messages = provider.loadMessages(for: conversation)
        } else {
            self.messages = self.localMessageStore.loadMessages(
                for: conversation.id,
                currentUserID: currentUserID
            )
        }
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
        let messageID = UUID()

        let optimisticMessage = Message(
            id: messageID,
            text: outgoingText,
            isIncoming: false,
            timestamp: Date(),
            status: .sending,
            visibility: .visible
        )

        messages = localMessageStore.appendMessage(
            optimisticMessage,
            for: conversation.id,
            currentUserID: currentUserID
        )

        messageText = ""
        errorMessage = nil

        guard
            let conversationService,
            let recipientUserID = conversation.recipientUserID
        else {
            markMessageAsSent(messageID)
            return
        }

        isSending = true

        Task {
            do {
                try await conversationService.sendMessage(
                    plaintext: outgoingText,
                    messageID: messageID,
                    to: recipientUserID,
                    conversationID: conversation.id
                )

                await MainActor.run {
                    self.markMessageAsSent(messageID)
                    self.isSending = false
                }
            } catch {
                await MainActor.run {
                    self.markMessageAsFailed(messageID)
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
                let result = try await conversationService.fetchInboxResilient()

                await MainActor.run {
                    self.mergeInboxMessages(result.messages)
                    self.mergeInboxFailures(result.failures)

                    if !result.failures.isEmpty {
                        self.errorMessage = """
                        Refreshed inbox, but \(result.failures.count) \
                        message(s) could not be decrypted.
                        """
                    }

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

    func hideMessage(_ id: UUID) {
        messages = localMessageStore.hideMessage(
            id,
            for: conversation.id,
            currentUserID: currentUserID
        )
    }

    func deleteMessage(_ id: UUID) {
        messages = localMessageStore.deleteMessage(
            id,
            for: conversation.id,
            currentUserID: currentUserID
        )
    }

    func deleteOutgoingUndeliveredMessage(_ id: UUID) {
        guard let conversationService else {
            deleteMessage(id)
            return
        }

        Task {
            do {
                try await conversationService.deleteUndeliveredMessage(id)

                await MainActor.run {
                    self.messages = self.localMessageStore.deleteMessage(
                        id,
                        for: self.conversation.id,
                        currentUserID: self.currentUserID
                    )
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
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
                status: .sent,
                visibility: .visible
            )
        }

        messages = localMessageStore.mergeIncomingMessages(
            newMessages,
            for: conversation.id,
            currentUserID: currentUserID
        )
    }

    private func mergeInboxFailures(_ failures: [InboxMessageFailure]) {
        let matchingFailures = failures.filter { $0.conversationID == conversation.id }

        guard !matchingFailures.isEmpty else { return }

        let placeholderMessages = matchingFailures.map { failure in
            Message(
                id: failure.envelopeID,
                text: failedDecryptPlaceholderText,
                isIncoming: true,
                timestamp: failure.createdAt,
                status: .failed,
                visibility: .visible
            )
        }

        messages = localMessageStore.mergeIncomingMessages(
            placeholderMessages,
            for: conversation.id,
            currentUserID: currentUserID
        )
    }

    private func markMessageAsSent(_ id: UUID) {
        guard let index = messages.firstIndex(where: { $0.id == id }) else { return }

        let old = messages[index]
        let updated = Message(
            id: old.id,
            text: old.text,
            isIncoming: old.isIncoming,
            timestamp: old.timestamp,
            status: .sent,
            visibility: old.visibility
        )

        messages[index] = updated
        messages = localMessageStore.replaceMessage(
            updated,
            for: conversation.id,
            currentUserID: currentUserID
        )
    }

    private func markMessageAsFailed(_ id: UUID) {
        guard let index = messages.firstIndex(where: { $0.id == id }) else { return }

        let old = messages[index]
        let updated = Message(
            id: old.id,
            text: old.text,
            isIncoming: old.isIncoming,
            timestamp: old.timestamp,
            status: .failed,
            visibility: old.visibility
        )

        messages[index] = updated
        messages = localMessageStore.replaceMessage(
            updated,
            for: conversation.id,
            currentUserID: currentUserID
        )
    }
}
