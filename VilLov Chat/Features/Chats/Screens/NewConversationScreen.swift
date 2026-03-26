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
    @State private var createdConversation: Conversation?

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
                            contactRow(for: contact)
                        }
                    }
                }

                if !viewModel.otherContacts.isEmpty {
                    Section("Other Contacts") {
                        ForEach(viewModel.otherContacts) { contact in
                            contactRow(for: contact)
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
        .navigationDestination(item: $createdConversation) { conversation in
            ChatScreen(
                viewModel: ChatViewModel(
                    conversation: conversation,
                    provider: messageProvider,
                    conversationService: conversationService
                )
            )
        }
        .alert(
            "Could not start conversation",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error")
        }
    }

    @ViewBuilder
    private func contactRow(for contact: Contact) -> some View {
        Button {
            Task {
                await createConversation(for: contact)
            }
        } label: {
            ContactRow(contact: contact)
        }
        .buttonStyle(.plain)
    }

    @MainActor
    private func createConversation(for contact: Contact) async {
        viewModel.errorMessage = nil
        viewModel.isCreatingConversation = true

        do {
            let conversation = try await viewModel.createConversation(from: contact)
            createdConversation = conversation
            viewModel.isCreatingConversation = false
        } catch {
            viewModel.errorMessage = error.localizedDescription
            viewModel.isCreatingConversation = false
        }
    }
}


