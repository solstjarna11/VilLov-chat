//
//  SignInScreen.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//


import SwiftUI

struct SignInScreen: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Sign In")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Sign in to your account using a registered passkey.")
                .font(.body)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 16) {
                Text("Security")
                    .font(.headline)

                Text("VilLov Chat uses passkeys for strong phishing-resistant authentication.")
                    .font(.body)
            }

            Spacer()

            NavigationLink {
                PasskeySetupScreen(mode: .authentication)
            } label: {
                Text("Continue with Passkey")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(32)
        .navigationTitle("Sign In")
    }
}