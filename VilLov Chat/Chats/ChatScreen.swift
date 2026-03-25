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

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 12) {
                    securityBanner

                    ForEach(messages) { message in
                        MessageBubble(message: message)
                    }
                }
                .padding()
            }

            Divider()

            messageComposer
        }
        .navigationTitle(conversation.title)
    }

    private var messageComposer: some View {
        HStack(spacing: 12) {
            TextField("Message", text: $messageText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...4)

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
        let newMessage = Message(
            id: UUID(),
            text: messageText,
            isIncoming: false,
            timestamp: Date(),
            status: .sending
        )

        messages.append(newMessage)
        messageText = ""
    }

    private var securityBanner: some View {
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
        }
        .padding()
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
    }
}
