//
//  PasskeySetupScreen.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//

import SwiftUI
import Observation

struct PasskeySetupScreen: View {
    @State private var viewModel: PasskeySetupViewModel

    init(viewModel: PasskeySetupViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    private var titleText: String {
        switch viewModel.mode {
        case .registration:
            return "Set Up Passkey"
        case .authentication:
            return "Use Passkey"
        }
    }

    private var descriptionText: String {
        switch viewModel.mode {
        case .registration:
            return "Create a passkey-style credential for this device to securely access your VilLov Chat account."
        case .authentication:
            return "Authenticate with your passkey-style credential to access your VilLov Chat account."
        }
    }

    private var actionText: String {
        if viewModel.isWorking {
            return "Please Wait..."
        }

        switch viewModel.mode {
        case .registration:
            return "Set Up Passkey"
        case .authentication:
            return "Authenticate"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(titleText)
                .font(.largeTitle)
                .fontWeight(.bold)

            Text(descriptionText)
                .font(.body)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 16) {
                Text("This flow is connected to the authentication service.")
                    .font(.body)

                Text("During development it uses the development passkey authenticator while preserving the same registration and sign-in structure.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Spacer()

            Button {
                Task {
                    await viewModel.performPasskeyFlow()
                }
            } label: {
                if viewModel.isWorking {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text(actionText)
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isWorking)
        }
        .padding(32)
        .navigationTitle(titleText)
    }
}
