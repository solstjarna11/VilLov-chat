//
//  ConversationSecurityScreen.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//

import SwiftUI
import Observation

struct ConversationSecurityScreen: View {
    @State private var viewModel: ConversationSecurityViewModel

    init(viewModel: ConversationSecurityViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        List {
            Section("Verification") {
                NavigationLink {
                    ContactVerificationScreen(
                        viewModel: ContactVerificationViewModel(
                            conversation: viewModel.conversation,
                            verificationData: viewModel.conversation.isVerified
                                ? MockContactVerificationData.verified
                                : MockContactVerificationData.unverified
                        )
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

