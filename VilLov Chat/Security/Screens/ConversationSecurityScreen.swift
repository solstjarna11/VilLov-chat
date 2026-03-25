//
//  ConversationSecurityScreen.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//

import SwiftUI

struct ConversationSecurityScreen: View {
    @StateObject private var viewModel: ConversationSecurityViewModel

    init(conversation: Conversation) {
        _viewModel = StateObject(
            wrappedValue: ConversationSecurityViewModel(conversation: conversation)
        )
    }

    var body: some View {
        List {
            Section("Verification") {
                NavigationLink {
                    ContactVerificationScreen(
                        conversation: viewModel.conversation,
                        verificationData: viewModel.conversation.isVerified
                            ? MockContactVerificationData.verified
                            : MockContactVerificationData.unverified
                    )
                } label: {
                    HStack {
                        Label("Verify Contact", systemImage: "checkmark.shield")
                        Spacer()
                        Text(viewModel.verificationStatusText)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Disappearing Messages") {
                Toggle("Enable Disappearing Messages", isOn: $viewModel.disappearingMessagesEnabled)

                if viewModel.disappearingMessagesEnabled {
                    Picker("Expiration", selection: $viewModel.selectedExpiration) {
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
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }
}
