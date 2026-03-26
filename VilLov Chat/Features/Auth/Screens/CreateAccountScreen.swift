//
//  CreateAccountScreen.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//

import SwiftUI

struct CreateAccountScreen: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Create Account")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Create your VilLov Chat account and set up secure authentication for this device.")
                .font(.body)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 16) {
                Text("What happens next")
                    .font(.headline)

                Text("• Create your account")
                Text("• Register a passkey on this device")
                Text("• Prepare secure messaging for your account")
            }
            .font(.body)

            Spacer()

            NavigationLink {
                PasskeySetupScreen(mode: .registration)
            } label: {
                Text("Continue")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(32)
        .navigationTitle("Create Account")
    }
}
