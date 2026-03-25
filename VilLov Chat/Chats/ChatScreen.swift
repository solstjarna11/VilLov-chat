//
//  ChatScreen.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//

import SwiftUI

struct ChatScreen: View {
    let conversation: Conversation

    @State private var messageText = ""
    @State private var messages: [Message] = Message.mockMessages
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        securityBanner

                        ForEach(Array(messages.enumerated()), id: \.element.id) { index, message in
                            let previous = index > 0 ? messages[index - 1] : nil

                            MessageBubble(
                                message: message,
                                isGroupedWithPrevious: previous?.isIncoming == message.isIncoming
                            )
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) {
                    guard let lastMessage = messages.last else { return }

                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
                .onAppear {
                    guard let lastMessage = messages.last else { return }

                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                }
            }

            Divider()

            messageComposer
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .navigationTitle(conversation.title)
        .onAppear {
            isInputFocused = true
        }
        .toolbar {
#if os(macOS)
            ToolbarItem(placement: .automatic) {
                NavigationLink {
                    ConversationSecurityScreen(conversation: conversation)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: conversation.isVerified ? "checkmark.shield.fill" : "exclamationmark.shield")
                        if conversation.disappearingEnabled {
                            Image(systemName: "timer")
                        }
                    }
                }
                .accessibilityLabel("Conversation Security")
            }
#else
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    ConversationSecurityScreen(conversation: conversation)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: conversation.isVerified ? "checkmark.shield.fill" : "exclamationmark.shield")
                        if conversation.disappearingEnabled {
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
            TextField("Message", text: $messageText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...4)
                .focused($isInputFocused)
                .submitLabel(.send)
                .onSubmit {
                    sendMessage()
                }
        

            Button {
                sendMessage()
            } label: {
                Image(systemName: "paperplane.fill")
            }
            .buttonStyle(.borderedProminent)
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
    }

    private func sendMessage() {
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let newMessage = Message(
            id: UUID(),
            text: trimmed,
            isIncoming: false,
            timestamp: Date(),
            status: .sending
        )

        messages.append(newMessage)
        messageText = ""

        isInputFocused = true
    }

    private var securityBanner: some View {
        NavigationLink {
            ConversationSecurityScreen(conversation: conversation)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Label(
                    conversation.isVerified ? "Identity verified" : "Identity not verified",
                    systemImage: conversation.isVerified ? "checkmark.shield.fill" : "exclamationmark.shield"
                )
                .font(.headline)

                if conversation.disappearingEnabled {
                    Label("Disappearing messages enabled", systemImage: "timer")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text("Open conversation security settings")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
