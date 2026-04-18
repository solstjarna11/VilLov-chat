//
//  ConversationListViewModel.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//

import Foundation
import Observation

@MainActor
@Observable
final class ConversationListViewModel {
    var searchText = ""
    var errorMessage: String?
    var isLoading = false
    private(set) var conversations: [Conversation] = []

    let currentUserID: String

    private let contactService: ContactService
    private let conversationDirectoryService: ConversationDirectoryService

    init(
        contactService: ContactService,
        conversationDirectoryService: ConversationDirectoryService,
        currentUserID: String
    ) {
        self.contactService = contactService
        self.conversationDirectoryService = conversationDirectoryService
        self.currentUserID = currentUserID
    }

    var filteredConversations: [Conversation] {
        let trimmedSearchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedSearchText.isEmpty else {
            return conversations
        }

        return conversations.filter {
            $0.title.localizedCaseInsensitiveContains(trimmedSearchText) ||
            $0.lastMessagePreview.localizedCaseInsensitiveContains(trimmedSearchText)
        }
    }

    var hasResults: Bool {
        !filteredConversations.isEmpty
    }

    func load() {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let apiContacts = try await contactService.fetchContacts()
                let apiConversations = try await conversationDirectoryService.fetchConversations()

                let contactsByUserID = Dictionary(
                    uniqueKeysWithValues: apiContacts.map {
                        (
                            $0.userID,
                            Contact(
                                id: UUID(),
                                name: $0.displayName,
                                trustState: .unverified,
                                userID: $0.userID
                            )
                        )
                    }
                )

                let mapped = apiConversations.map { apiConversation in
                    let otherUserID =
                        apiConversation.participantAUserID == currentUserID
                        ? apiConversation.participantBUserID
                        : apiConversation.participantAUserID

                    let otherContact = contactsByUserID[otherUserID]

                    return Conversation(
                        id: apiConversation.conversationID,
                        title: otherContact?.name ?? otherUserID,
                        lastMessagePreview: "",
                        lastActivity: apiConversation.createdAt,
                        unreadCount: 0,
                        trustState: otherContact?.trustState ?? .unverified,
                        disappearingEnabled: false,
                        recipientUserID: otherUserID
                    )
                }

                await MainActor.run {
                    self.conversations = mapped.sorted { $0.lastActivity > $1.lastActivity }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    func addConversation(_ conversation: Conversation) {
        guard !conversations.contains(where: { $0.id == conversation.id }) else { return }
        conversations.insert(conversation, at: 0)
    }
}
