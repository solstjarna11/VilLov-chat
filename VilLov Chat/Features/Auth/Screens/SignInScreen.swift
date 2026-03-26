//
//  SignInScreen.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//


import SwiftUI
import Observation

struct SignInScreen: View {
    @State private var viewModel: SignInViewModel

    init(viewModel: SignInViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel

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

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Spacer()

            Button {
                viewModel.signIn()
            } label: {
                Group {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Continue with Passkey")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isLoading)
        }
        .padding(32)
        .navigationTitle("Sign In")
    }
}

#Preview {
    NavigationStack {
        SignInScreen(
            viewModel: SignInViewModel(
                authService: PreviewAuthService.make(),
                session: AppSession(tokenStore: AuthTokenStore())
            )
        )
    }
}
