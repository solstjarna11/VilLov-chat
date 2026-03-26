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
            Spacer()

            VStack(alignment: .leading, spacing: 12) {
                Text("VilLov Chat")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Private messaging with passkey-based sign in.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 16) {
                Text("Security")
                    .font(.headline)

                Text("VilLov Chat uses passkeys for strong phishing-resistant authentication. Your passkey stays with your device or password manager.")
                    .font(.body)
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Spacer()

            VStack(spacing: 12) {
                Button {
                    viewModel.signInWithDefaultPasskey()
                } label: {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Continue with Passkey")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoading)

                if let rememberedName = viewModel.rememberedAccountName {
                    Button {
                        viewModel.signInWithRememberedAccount()
                    } label: {
                        Text("Continue as \(rememberedName)")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.isLoading)
                }

                Button {
                    viewModel.showsAccountPicker = true
                } label: {
                    Text("Use another account")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isLoading)
            }
        }
        .padding(32)
        .navigationTitle("Sign In")
        .sheet(isPresented: $viewModel.showsAccountPicker) {
            NavigationStack {
                List {
                    Section("Development Accounts") {
                        Picker("Account", selection: $viewModel.selectedDevAccount) {
                            ForEach(DevAuthAccount.allCases) { account in
                                Text(account.displayName).tag(account)
                            }
                        }
                        .pickerStyle(.inline)
                    }

                    Section {
                        Button {
                            viewModel.showsAccountPicker = false
                            viewModel.signInWithSelectedDevAccount()
                        } label: {
                            Text("Continue with Selected Account")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .navigationTitle("Use Another Account")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            viewModel.showsAccountPicker = false
                        }
                    }
                }
            }
        }
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
