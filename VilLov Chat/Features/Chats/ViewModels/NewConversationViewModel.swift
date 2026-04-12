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
    var isLoading = false
    var errorMessage: String?
    private(set) var contacts: [Contact] = []

    private let contactService: ContactService
    private let conversationService: ConversationServicing

    init(
        contactService: ContactService,
        conversationService: ConversationServicing
    ) {
        self.contactService = contactService
        self.conversationService = conversationService
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

    func load() {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let apiContacts = try await contactService.fetchContacts()

                let mapped = apiContacts.map {
                    Contact(
                        id: UUID(),
                        name: $0.displayName,
                        trustState: .unverified,
                        userID: $0.userID
                    )
                }

                await MainActor.run {
                    self.contacts = mapped.sorted { $0.name < $1.name }
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

    func createConversation(from contact: Contact) async throws -> Conversation {
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
