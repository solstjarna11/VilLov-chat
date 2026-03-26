//
//  NewConversationScreen.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//

import SwiftUI
import Observation

struct NewConversationScreen: View {
    @State private var viewModel: NewConversationViewModel

    private let messageProvider: MessageProviding
    private let conversationService: ConversationServicing?

    init(
        viewModel: NewConversationViewModel,
        messageProvider: MessageProviding,
        conversationService: ConversationServicing? = nil
    ) {
        _viewModel = State(initialValue: viewModel)
        self.messageProvider = messageProvider
        self.conversationService = conversationService
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        List {
            if viewModel.hasResults {
                if !viewModel.verifiedContacts.isEmpty {
                    Section("Verified") {
                        ForEach(viewModel.verifiedContacts) { contact in
                            contactNavigationLink(for: contact)
                        }
                    }
                }

                if !viewModel.otherContacts.isEmpty {
                    Section("Other Contacts") {
                        ForEach(viewModel.otherContacts) { contact in
                            contactNavigationLink(for: contact)
                        }
                    }
                }
            }
        }
        .navigationTitle("New Conversation")
        .searchable(text: $viewModel.searchText, prompt: "Search contacts")
        .overlay {
            if !viewModel.hasResults {
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
        let conversation = viewModel.makeConversation(from: contact)

        NavigationLink {
            ChatScreen(
                viewModel: ChatViewModel(
                    conversation: conversation,
                    provider: messageProvider,
                    conversationService: conversationService
                )
            )
        } label: {
            ContactRow(contact: contact)
        }
    }
}

#Preview("Contacts Available") {
    NavigationStack {
        NewConversationScreen(
            viewModel: NewConversationViewModel(
                provider: PopulatedContactProvider()
            ),
            messageProvider: EmptyMessageProvider(),
            conversationService: nil
        )
    }
}

#Preview("No Contacts") {
    NavigationStack {
        NewConversationScreen(
            viewModel: NewConversationViewModel(
                provider: EmptyContactProvider()
            ),
            messageProvider: EmptyMessageProvider(),
            conversationService: nil
        )
    }
}
