//
//  WelcomeScreen.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//

import SwiftUI

struct WelcomeScreen: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 12) {
                    Text("VilLov Chat")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Private messaging with strong security by default.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                VStack(spacing: 12) {
                    Button("Create Account") {
                        // navigate to registration/passkey setup flow
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)

                    Button("Sign In") {
                        // navigate to authentication flow
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding()
        }
    }
}
