//
//  ChatScreen.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//

import SwiftUI

struct ChatScreen: View {
    @StateObject private var viewModel: ChatViewModel
    @FocusState private var isInputFocused: Bool

    init(conversation: Conversation) {
        _viewModel = StateObject(wrappedValue: ChatViewModel(conversation: conversation))
    }
    init(viewModel: ChatViewModel){
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack(spacing: 0) {
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

            messageComposer
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .navigationTitle(viewModel.conversation.title)
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    ConversationSecurityScreen(conversation: viewModel.conversation)
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
            ToolbarItem(placement: .automatic) {
                NavigationLink {
                    ConversationSecurityScreen(conversation: viewModel.conversation)
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
    }

    private var messageComposer: some View {
        HStack(spacing: 12) {
            TextField("Message", text: $viewModel.messageText, axis: .vertical)
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
            ConversationSecurityScreen(conversation: viewModel.conversation)
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

#Preview {
    NavigationStack {
        ChatScreen(
            viewModel: ChatViewModel(
                conversation: Conversation.mockData[0],
                provider: MockDataProvider()
            )
        )
    }
}
