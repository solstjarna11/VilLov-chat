//
//  NewConversationScreen.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//

import SwiftUI

struct NewConversationScreen: View {
    @State private var searchText = ""
    @State private var contacts = Contact.mockData

    private var filteredContacts: [Contact] {
        let trimmedSearchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedSearchText.isEmpty else {
            return contacts
        }

        return contacts.filter {
            $0.name.localizedCaseInsensitiveContains(trimmedSearchText)
        }
    }

    private var verifiedContacts: [Contact] {
        filteredContacts.filter { $0.trustState == .verified }
    }

    private var otherContacts: [Contact] {
        filteredContacts.filter { $0.trustState != .verified }
    }

    private var hasResults: Bool {
        !filteredContacts.isEmpty
    }

    var body: some View {
        List {
            if hasResults {
                if !verifiedContacts.isEmpty {
                    Section("Verified") {
                        ForEach(verifiedContacts) { contact in
                            contactNavigationLink(for: contact)
                        }
                    }
                }

                if !otherContacts.isEmpty {
                    Section("Other Contacts") {
                        ForEach(otherContacts) { contact in
                            contactNavigationLink(for: contact)
                        }
                    }
                }
            }
        }
        .navigationTitle("New Conversation")
        .searchable(text: $searchText, prompt: "Search contacts")
        .overlay {
            if !hasResults {
                ContentUnavailableView(
                    "No Contacts Found",
                    systemImage: "person.crop.circle.badge.exclamationmark",
                    description: Text("Try searching with a different name.")
                )
            }
        }
    }

    @ViewBuilder
    private func contactNavigationLink(for contact: Contact) -> some View {
        NavigationLink {
            ChatScreen(conversation: makeConversation(from: contact))
        } label: {
            ContactRow(contact: contact)
        }
    }

    private func makeConversation(from contact: Contact) -> Conversation {
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

#Preview {
    NavigationStack {
        NewConversationScreen()
    }
}

