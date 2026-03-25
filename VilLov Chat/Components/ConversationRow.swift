//
//  ConversationRow.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//

import SwiftUI

struct ConversationRow: View {
    let conversation: Conversation

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            avatar

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(conversation.title)
                        .font(.headline)
                        .lineLimit(1)

                    if conversation.isVerified {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.caption)
                    }

                    if conversation.disappearingEnabled {
                        Image(systemName: "timer")
                            .font(.caption)
                    }

                    Spacer()

                    Text(conversation.lastActivity, style: .time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(alignment: .center, spacing: 8) {
                    Text(conversation.lastMessagePreview)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    Spacer(minLength: 8)

                    if conversation.unreadCount > 0 {
                        unreadBadge
                    }
                }
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }

    private var avatar: some View {
        Circle()
            .fill(.quaternary)
            .frame(width: 44, height: 44)
            .overlay {
                Text(initials(from: conversation.title))
                    .font(.subheadline.weight(.semibold))
            }
    }

    private var unreadBadge: some View {
        Text("\(conversation.unreadCount)")
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(.blue))
            .foregroundStyle(.white)
    }

    private func initials(from title: String) -> String {
        let parts = title
            .split(separator: " ")
            .prefix(2)

        let initials = parts.compactMap { $0.first }.map(String.init).joined()
        return initials.isEmpty ? "?" : initials
    }
}
