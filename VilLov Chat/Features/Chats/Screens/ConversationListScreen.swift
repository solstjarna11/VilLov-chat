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
    private let contactService: ContactService
    private let conversationService: ConversationServicing
    private let identityTrustStore: IdentityTrustStore
    private let localKeyStore: LocalKeyStore

    init(
        viewModel: ConversationListViewModel,
        messageProvider: MessageProviding,
        contactService: ContactService,
        conversationService: ConversationServicing,
        identityTrustStore: IdentityTrustStore,
        localKeyStore: LocalKeyStore
    ) {
        _viewModel = State(initialValue: viewModel)
        self.messageProvider = messageProvider
        self.contactService = contactService
        self.conversationService = conversationService
        self.identityTrustStore = identityTrustStore
        self.localKeyStore = localKeyStore
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            List(viewModel.filteredConversations) { conversation in
                NavigationLink {
                    ChatScreen(
                        viewModel: ChatViewModel(
                            conversation: conversation,
                            currentUserID: viewModel.currentUserID,
                            provider: messageProvider,
                            conversationService: conversationService
                        ),
                        identityTrustStore: identityTrustStore,
                        localKeyStore: localKeyStore
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
                                contactService: contactService,
                                conversationService: conversationService,
                                identityTrustStore: identityTrustStore,
                                currentUserID: viewModel.currentUserID
                            ),
                            currentUserID: viewModel.currentUserID,
                            messageProvider: messageProvider,
                            conversationService: conversationService,
                            identityTrustStore: identityTrustStore,
                            localKeyStore: localKeyStore
                        )
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                    .accessibilityLabel("New Conversation")
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView("Loading conversations...")
                } else if !viewModel.hasResults {
                    ContentUnavailableView(
                        "No Conversations",
                        systemImage: "message",
                        description: Text("Start a new secure conversation to begin messaging.")
                    )
                }
            }
            .alert(
                "Could not load conversations",
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
            .task {
                viewModel.load()
            }
        }
    }
}
