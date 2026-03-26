//
//  PasskeySetupScreen.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//

import SwiftUI

struct PasskeySetupScreen: View {
    enum Mode {
        case registration
        case authentication
    }

    let mode: Mode

    var titleText: String {
        switch mode {
        case .registration:
            return "Set Up Passkey"
        case .authentication:
            return "Use Passkey"
        }
    }

    var descriptionText: String {
        switch mode {
        case .registration:
            return "You will create a passkey for this device to securely access your VilLov Chat account."
        case .authentication:
            return "Authenticate with your existing passkey to access your VilLov Chat account."
        }
    }

    var actionText: String {
        switch mode {
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
                Text("This screen will later connect to the real authentication service and platform passkey APIs.")
                    .font(.body)

                Text("The UI and flow are being implemented now with the final structure in place.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(actionText) {
                // later: connect to real passkey registration/authentication flow
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(32)
        .navigationTitle(titleText)
    }
}
