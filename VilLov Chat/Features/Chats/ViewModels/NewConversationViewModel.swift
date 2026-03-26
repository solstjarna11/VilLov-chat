//
//  NewConversationViewModel.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//


import Foundation
import Observation

@MainActor
@Observable
final class NewConversationViewModel {
    var searchText = ""
    var isCreatingConversation = false
    var errorMessage: String?
    private(set) var contacts: [Contact]

    private let provider: ContactProviding
    private let conversationService: ConversationServicing?
    private let currentUserID: String?

    init(
        provider: ContactProviding,
        conversationService: ConversationServicing? = nil,
        currentUserID: String? = nil
    ) {
        self.provider = provider
        self.conversationService = conversationService
        self.currentUserID = currentUserID
        self.contacts = provider.loadContacts(for: currentUserID)
    }

    var filteredContacts: [Contact] {
        let trimmedSearchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedSearchText.isEmpty else {
            return contacts
        }

        return contacts.filter {
            $0.name.localizedCaseInsensitiveContains(trimmedSearchText)
        }
    }

    var verifiedContacts: [Contact] {
        filteredContacts.filter { $0.trustState == .verified }
    }

    var otherContacts: [Contact] {
        filteredContacts.filter { $0.trustState != .verified }
    }

    var hasResults: Bool {
        !filteredContacts.isEmpty
    }

    func createConversation(from contact: Contact) async throws -> Conversation {
        guard let conversationService else {
            throw NSError(
                domain: "NewConversationViewModel",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Conversation service is unavailable."]
            )
        }

        guard let recipientUserID = contact.userID else {
            throw NSError(
                domain: "NewConversationViewModel",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Contact is missing a backend user ID."]
            )
        }

        let conversationID = try await conversationService.getOrCreateConversation(with: recipientUserID)

        return Conversation(
            id: conversationID,
            title: contact.name,
            lastMessagePreview: "",
            lastActivity: Date(),
            unreadCount: 0,
            trustState: contact.trustState,
            disappearingEnabled: false,
            recipientUserID: recipientUserID
        )
    }
}
