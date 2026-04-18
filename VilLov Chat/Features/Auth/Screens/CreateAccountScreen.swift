//
//  CreateAccountScreen.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//

import SwiftUI
import Observation

struct CreateAccountScreen: View {
    let environment: AppEnvironment

    @State private var viewModel = CreateAccountViewModel()
    @State private var shouldNavigateToPasskeySetup = false

    var body: some View {
        @Bindable var viewModel = viewModel

        VStack(alignment: .leading, spacing: 24) {
            Text("Create Account")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Create your VilLov Chat account and set up secure authentication for this device.")
                .font(.body)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 16) {
                Text("Account Details")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Username")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    TextField("e.g. lovisa", text: $viewModel.userHandle)
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.asciiCapable)
                        #endif
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    Text("Used as your account identifier.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Display Name")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    TextField("e.g. Lovisa", text: $viewModel.displayName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    Text("Shown in the app as your profile name.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 16) {
                Text("What happens next")
                    .font(.headline)

                Text("• Create your account")
                Text("• Register a passkey on this device")
                Text("• Prepare secure messaging for your account")
            }
            .font(.body)

            if let validationError = viewModel.validationError {
                Text(validationError)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Spacer()

            Button {
                shouldNavigateToPasskeySetup = true
            } label: {
                Text("Continue")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.canContinue)
        }
        .padding(32)
        .navigationTitle("Create Account")
        .navigationDestination(isPresented: $shouldNavigateToPasskeySetup) {
            PasskeySetupScreen(
                viewModel: PasskeySetupViewModel(
                    mode: .registration,
                    authService: environment.authService,
                    session: environment.session,
                    userHandle: viewModel.normalizedUserHandle,
                    rememberedAccountName: viewModel.trimmedDisplayName,
                    keyDirectoryService: environment.keyDirectoryService
                )
            )
        }
    }
}
