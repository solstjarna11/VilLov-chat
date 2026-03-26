//
//  ContactVerificationScreen.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//

import SwiftUI
import Observation

struct ContactVerificationScreen: View {
    @State private var viewModel: ContactVerificationViewModel

    init(viewModel: ContactVerificationViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                verificationStatusCard
                qrPlaceholderCard
                safetyNumberCard
                verificationInstructionsCard
            }
            .padding()
        }
        .navigationTitle("Verify Contact")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private var verificationStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(
                viewModel.statusTitle,
                systemImage: viewModel.statusSystemImage
            )
            .font(.headline)

            Text("Verification helps confirm that you are communicating with the intended person and not an attacker intercepting keys.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var qrPlaceholderCard: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 16)
                .fill(.quaternary)
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .overlay {
                    VStack(spacing: 12) {
                        Image(systemName: "qrcode")
                            .font(.system(size: 56))
                        Text("QR Verification")
                            .font(.headline)
                        Text(viewModel.qrCodeDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }

            Text("Scan each other’s code in person to verify identities.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var safetyNumberCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Safety Number")
                .font(.headline)

            Text(viewModel.safetyNumber)
                .font(.system(.body, design: .monospaced))

            Button("Copy Safety Number") {
                viewModel.copySafetyNumberToClipboard()
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var verificationInstructionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How to Verify")
                .font(.headline)

            Text("Compare the safety number with your contact or scan the QR code while physically together.")
            Text("If the values match, you can trust that the conversation keys belong to the intended contact.")
            Text("If they do not match, do not trust the conversation until the issue is resolved.")
        }
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview("Verified Contact") {
    NavigationStack {
        ContactVerificationScreen(
            viewModel: ContactVerificationViewModel(
                conversation: Conversation(
                    id: UUID(),
                    title: "Alice Johnson",
                    lastMessagePreview: "",
                    lastActivity: Date(),
                    unreadCount: 0,
                    trustState: .verified,
                    disappearingEnabled: false
                ),
                verificationData: MockContactVerificationData.verified
            )
        )
    }
}

#Preview("Unverified Contact") {
    NavigationStack {
        ContactVerificationScreen(
            viewModel: ContactVerificationViewModel(
                conversation: Conversation(
                    id: UUID(),
                    title: "Bob Smith",
                    lastMessagePreview: "",
                    lastActivity: Date(),
                    unreadCount: 0,
                    trustState: .unverified,
                    disappearingEnabled: false
                ),
                verificationData: MockContactVerificationData.unverified
            )
        )
    }
}
