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
    private(set) var contacts: [Contact]

    private let provider: ContactProviding

    init(provider: ContactProviding) {
        self.provider = provider
        self.contacts = provider.loadContacts()
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

    func makeConversation(from contact: Contact) -> Conversation {
        Conversation(
            id: UUID(),
            title: contact.name,
            lastMessagePreview: "",
            lastActivity: Date(),
            unreadCount: 0,
            trustState: contact.trustState,
            disappearingEnabled: false
        )
    }
}
