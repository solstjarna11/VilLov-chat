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
                .disabled(viewModel.isLoading || !viewModel.hasRememberedAccounts)

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
                    viewModel.refreshRememberedAccounts()
                    viewModel.showsAccountPicker = true
                } label: {
                    Text("Use another account")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isLoading || !viewModel.hasRememberedAccounts)
            }
        }
        .padding(32)
        .navigationTitle("Sign In")
        .sheet(isPresented: $viewModel.showsAccountPicker) {
            NavigationStack {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Choose an account to continue.")
                        .foregroundStyle(.secondary)

                    Picker("Account", selection: $viewModel.selectedAccount) {
                        ForEach(viewModel.rememberedAccounts) { account in
                            Text(account.displayName).tag(Optional(account))
                        }
                    }
                    #if os(macOS)
                    .pickerStyle(.radioGroup)
                    #else
                    .pickerStyle(.inline)
                    #endif

                    Spacer()

                    HStack {
                        Spacer()

                        Button("Cancel") {
                            viewModel.showsAccountPicker = false
                        }

                        Button {
                            viewModel.showsAccountPicker = false
                            viewModel.signInWithSelectedAccount()
                        } label: {
                            Text("Continue")
                                .frame(minWidth: 100)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.selectedAccount == nil)
                    }
                }
                .padding(24)
                .frame(minWidth: 420, minHeight: 260)
                .navigationTitle("Use Another Account")
            }
        }
        .onAppear {
            viewModel.refreshRememberedAccounts()
        }
    }
}
