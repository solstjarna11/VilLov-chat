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

    var filteredContacts: [Contact] {
        guard !searchText.isEmpty else { return contacts }

        return contacts.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        List(filteredContacts) { contact in
            NavigationLink {
                ChatScreen(
                    conversation: Conversation(
                        id: UUID(),
                        title: contact.name,
                        lastMessagePreview: "",
                        lastActivity: Date(),
                        unreadCount: 0,
                        trustState: contact.isVerified ? .verified : .unverified,
                        disappearingEnabled: false
                    )
                )
            } label: {
                ContactRow(contact: contact)
            }
        }
        .navigationTitle("New Conversation")
        .searchable(text: $searchText, prompt: "Search contacts")
    }
}

