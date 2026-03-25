//
//  ConversationSecurityScreen.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//

import SwiftUI

struct ConversationSecurityScreen: View {
    let conversation: Conversation
    @State private var disappearingMessagesEnabled: Bool
    @State private var selectedExpiration: MessageExpiration = .oneDay

    init(conversation: Conversation) {
        self.conversation = conversation
        _disappearingMessagesEnabled = State(initialValue: conversation.disappearingEnabled)
    }

    var body: some View {
        List {
            Section("Verification") {
                NavigationLink {
                    ContactVerificationScreen(
                        conversation: conversation,
                        verificationData: conversation.isVerified
                            ? MockContactVerificationData.verified
                            : MockContactVerificationData.unverified
                    )
                } label: {
                    HStack {
                        Label("Verify Contact", systemImage: "checkmark.shield")
                        Spacer()
                        if conversation.isVerified {
                            Text("Verified")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Disappearing Messages") {
                Toggle("Enable Disappearing Messages", isOn: $disappearingMessagesEnabled)

                if disappearingMessagesEnabled {
                    Picker("Expiration", selection: $selectedExpiration) {
                        ForEach(MessageExpiration.allCases) { expiration in
                            Text(expiration.title).tag(expiration)
                        }
                    }
                }
            }

            Section("Session") {
                Button("Refresh Session") {
                    // hook into real session reset / renegotiation later
                }

                Button("View Safety Details") {
                    // optional future route for deeper crypto/session details
                }
            }
        }
        .navigationTitle("Conversation Security")
        .navigationBarTitleDisplayMode(.inline)
    }
}

enum MessageExpiration: String, CaseIterable, Identifiable {
    case thirtyMinutes
    case oneHour
    case oneDay
    case oneWeek

    var id: String { rawValue }

    var title: String {
        switch self {
        case .thirtyMinutes:
            return "30 Minutes"
        case .oneHour:
            return "1 Hour"
        case .oneDay:
            return "1 Day"
        case .oneWeek:
            return "1 Week"
        }
    }
}
