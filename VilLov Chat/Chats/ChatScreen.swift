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

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 12) {
                    securityBanner
                        .padding(.horizontal)
                        .padding(.top)

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity)
            }

            Divider()

            HStack(spacing: 12) {
                TextField("Message", text: $messageText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)

                Button {
                    // send message later
                } label: {
                    Image(systemName: "paperplane.fill")
                }
                .buttonStyle(.borderedProminent)
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
        .navigationTitle(conversation.title)
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
    }
}
