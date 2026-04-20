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
    private let identityTrustStore: IdentityTrustStore

    init(
        contactService: ContactService,
        conversationDirectoryService: ConversationDirectoryService,
        currentUserID: String,
        identityTrustStore: IdentityTrustStore
    ) {
        self.contactService = contactService
        self.conversationDirectoryService = conversationDirectoryService
        self.currentUserID = currentUserID
        self.identityTrustStore = identityTrustStore
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
                        let trustState = identityTrustStore.identity(
                            for: $0.userID,
                            currentUserID: currentUserID
                        )?.trustState ?? .unverified

                        return (
                            $0.userID,
                            Contact(
                                id: UUID(),
                                name: $0.displayName,
                                trustState: trustState,
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
                    let trustState = identityTrustStore.identity(
                        for: otherUserID,
                        currentUserID: currentUserID
                    )?.trustState ?? otherContact?.trustState ?? .unverified

                    return Conversation(
                        id: apiConversation.conversationID,
                        title: otherContact?.name ?? otherUserID,
                        lastMessagePreview: "",
                        lastActivity: apiConversation.createdAt,
                        unreadCount: 0,
                        trustState: trustState,
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
