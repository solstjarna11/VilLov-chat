//
//  MessageBubble.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//

import SwiftUI

struct MessageBubble: View {
    let message: Message
    let isGroupedWithPrevious: Bool

    var body: some View {
        HStack {
            if message.isIncoming {
                bubble
                Spacer(minLength: 40)
            } else {
                Spacer(minLength: 40)
                bubble
            }
        }
        .padding(.top, isGroupedWithPrevious ? 2 : 10)
        .padding(.horizontal)
    }

    private var bubble: some View {
        VStack(alignment: message.isIncoming ? .leading : .trailing, spacing: 4) {
            Text(message.text)
                .font(.body)

            HStack(spacing: 4) {
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                if !message.isIncoming {
                    statusIcon
                }
            }
        }
        .padding(10)
        .background(
            message.isIncoming
            ? Color(.quaternarySystemFill)
            : Color.accentColor
        )
        .foregroundStyle(message.isIncoming ? Color.primary : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var statusIcon: some View {
        Group {
            switch message.status {
            case .sending:
                ProgressView()
                    .scaleEffect(0.6)
            case .sent:
                Image(systemName: "checkmark")
            case .delivered:
                Image(systemName: "checkmark.circle")
            case .read:
                Image(systemName: "checkmark.circle.fill")
            case .failed:
                Image(systemName: "exclamationmark.circle")
            }
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
}
