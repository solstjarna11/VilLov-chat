//
//  ConversationListScreen.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//

import SwiftUI
import Observation

struct ConversationListScreen: View {
    @State private var viewModel: ConversationListViewModel

    private let messageProvider: MessageProviding
    private let contactProvider: ContactProviding

    init(
        viewModel: ConversationListViewModel,
        messageProvider: MessageProviding,
        contactProvider: ContactProviding
    ) {
        _viewModel = State(initialValue: viewModel)
        self.messageProvider = messageProvider
        self.contactProvider = contactProvider
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            List(viewModel.filteredConversations) { conversation in
                NavigationLink {
                    ChatScreen(
                        viewModel: ChatViewModel(
                            conversation: conversation,
                            provider: messageProvider
                        )
                    )
                } label: {
                    ConversationRow(conversation: conversation)
                }
            }
            .listStyle(.inset)
            .navigationTitle("Chats")
            .searchable(text: $viewModel.searchText, prompt: "Search conversations")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink {
                        NewConversationScreen(
                            viewModel: NewConversationViewModel(
                                provider: contactProvider
                            ),
                            messageProvider: messageProvider
                        )
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                    .accessibilityLabel("New Conversation")
                }
            }
            .overlay {
                if !viewModel.hasResults {
                    ContentUnavailableView(
                        "No Conversations",
                        systemImage: "message",
                        description: Text("Start a new secure conversation to begin messaging.")
                    )
                }
            }
        }
    }
}

#Preview("Populated Conversations") {
    ConversationListScreen(
        viewModel: ConversationListViewModel(
            provider: PopulatedConversationProvider()
        ),
        messageProvider: EmptyMessageProvider(),
        contactProvider: EmptyContactProvider()
    )
}

#Preview("Empty Conversations") {
    ConversationListScreen(
        viewModel: ConversationListViewModel(
            provider: EmptyConversationProvider()
        ),
        messageProvider: EmptyMessageProvider(),
        contactProvider: EmptyContactProvider()
    )
}
