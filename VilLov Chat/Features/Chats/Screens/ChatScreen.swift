//
//  ChatScreen.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//


import SwiftUI
import Observation

struct ChatScreen: View {
    @State private var viewModel: ChatViewModel
    @FocusState private var isInputFocused: Bool

    private let identityTrustStore: IdentityTrustStore
    private let localKeyStore: LocalKeyStore

    init(
        viewModel: ChatViewModel,
        identityTrustStore: IdentityTrustStore,
        localKeyStore: LocalKeyStore
    ) {
        _viewModel = State(initialValue: viewModel)
        self.identityTrustStore = identityTrustStore
        self.localKeyStore = localKeyStore
    }

    var body: some View {
        @Bindable var bindableViewModel = viewModel

        VStack(spacing: 0) {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 8)
            }

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        securityBanner

                        ForEach(Array(viewModel.messages.enumerated()), id: \.element.id) { index, message in
                            let previous = index > 0 ? viewModel.messages[index - 1] : nil

                            MessageBubble(
                                message: message,
                                isGroupedWithPrevious: previous?.isIncoming == message.isIncoming
                            )
                            .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) {
                    guard let lastMessage = viewModel.messages.last else { return }

                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
                .onAppear {
                    guard let lastMessage = viewModel.messages.last else { return }
                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                }
            }

            Divider()

            messageComposer(
                viewModel: viewModel,
                bindableViewModel: $bindableViewModel
            )
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .navigationTitle(viewModel.conversation.title)
        .toolbar {
            #if os(iOS)
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    viewModel.refreshInbox()
                } label: {
                    if viewModel.isRefreshingInbox {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .accessibilityLabel("Refresh Inbox")

                NavigationLink {
                    ConversationSecurityScreen(
                        viewModel: ConversationSecurityViewModel(
                            conversation: viewModel.conversation,
                            currentUserID: viewModel.currentUserID,
                            identityTrustStore: identityTrustStore,
                            localKeyStore: localKeyStore
                        )
                    )
                } label: {
                    HStack(spacing: 6) {
                        VerificationBadge(isVerified: viewModel.conversation.isVerified)
                        if viewModel.conversation.disappearingEnabled {
                            Image(systemName: "timer")
                        }
                    }
                }
                .accessibilityLabel("Conversation Security")
            }
            #else
            ToolbarItemGroup(placement: .automatic) {
                Button {
                    viewModel.refreshInbox()
                } label: {
                    if viewModel.isRefreshingInbox {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .accessibilityLabel("Refresh Inbox")

                NavigationLink {
                    ConversationSecurityScreen(
                        viewModel: ConversationSecurityViewModel(
                            conversation: viewModel.conversation,
                            currentUserID: viewModel.currentUserID,
                            identityTrustStore: identityTrustStore,
                            localKeyStore: localKeyStore
                        )
                    )
                } label: {
                    HStack(spacing: 6) {
                        VerificationBadge(isVerified: viewModel.conversation.isVerified)
                        if viewModel.conversation.disappearingEnabled {
                            Image(systemName: "timer")
                        }
                    }
                }
                .accessibilityLabel("Conversation Security")
            }
            #endif
        }
        .task {
            viewModel.refreshInbox()
        }
    }

    private func messageComposer(
        viewModel: ChatViewModel,
        bindableViewModel: Bindable<ChatViewModel>
    ) -> some View {
        HStack(spacing: 12) {
            TextField("Message", text: bindableViewModel.messageText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...4)
                .focused($isInputFocused)
                .submitLabel(.send)
                .onSubmit {
                    sendMessageAndRestoreFocus()
                }

            Button {
                sendMessageAndRestoreFocus()
            } label: {
                Image(systemName: "paperplane.fill")
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.canSendMessage)
        }
        .padding()
    }

    private var securityBanner: some View {
        NavigationLink {
            ConversationSecurityScreen(
                viewModel: ConversationSecurityViewModel(
                    conversation: viewModel.conversation,
                    currentUserID: viewModel.currentUserID,
                    identityTrustStore: identityTrustStore,
                    localKeyStore: localKeyStore
                )
            )
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                SecurityStatusBanner(
                    isVerified: viewModel.conversation.isVerified,
                    disappearingMessagesEnabled: viewModel.conversation.disappearingEnabled
                )

                Text("Open conversation security settings")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }

    private func sendMessageAndRestoreFocus() {
        viewModel.sendMessage()
        isInputFocused = true
    }
}
