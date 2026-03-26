//
//  WelcomeScreen.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//

import SwiftUI

struct WelcomeScreen: View {
    let environment: AppEnvironment

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                Spacer()

                VStack(alignment: .leading, spacing: 12) {
                    Text("VilLov Chat")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Private messaging designed for secure conversations, trusted devices, and modern authentication.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 16) {
                    Label("Passkey-based authentication", systemImage: "key.fill")
                    Label("End-to-end encrypted messaging", systemImage: "lock.shield.fill")
                    Label("Device and conversation verification", systemImage: "checkmark.shield.fill")
                }
                .font(.body)

                Spacer()

                VStack(spacing: 12) {
                    NavigationLink {
                        SignInScreen(
                            viewModel: SignInViewModel(
                                authService: environment.authService,
                                session: environment.session
                            )
                        )
                    } label: {
                        Text("Sign In")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    NavigationLink {
                        CreateAccountScreen()
                    } label: {
                        Text("Create Account")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(32)
            .navigationTitle("Welcome")
        }
    }
}

#Preview {
    WelcomeScreen(
        environment: AppEnvironment(
            session: AppSession(tokenStore: AuthTokenStore()),
            providers: AppProviders.mock,
            authService: PreviewAuthService.make(),
            conversationService: PreviewConversationService(),
            keyDirectoryService: KeyDirectoryService(
                apiClient: APIClient(
                    baseURL: URL(string: "https://api.villov.example")!,
                    tokenStore: AuthTokenStore()
                )
            ),
            relayService: RelayService(
                apiClient: APIClient(
                    baseURL: URL(string: "https://api.villov.example")!,
                    tokenStore: AuthTokenStore()
                )
            )
        )
    )
}
