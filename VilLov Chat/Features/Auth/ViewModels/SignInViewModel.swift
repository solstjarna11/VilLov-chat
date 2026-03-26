//
//  SignInViewModel.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 26.3.2026.
//


import Foundation
import Observation

@MainActor
@Observable
final class SignInViewModel {
    var isLoading = false
    var errorMessage: String?
    var selectedDevAccount: DevAuthAccount = .alice
    var showsAccountPicker = false

    private let authService: AuthService
    private let session: AppSession

    init(
        authService: AuthService,
        session: AppSession
    ) {
        self.authService = authService
        self.session = session
    }

    var rememberedAccountName: String? {
        session.rememberedAccountName
    }

    func signInWithDefaultPasskey() {
        signIn(using: nil, rememberedName: session.rememberedAccountName)
    }

    func signInWithRememberedAccount() {
        signIn(using: session.currentUserID, rememberedName: session.rememberedAccountName)
    }

    func signInWithSelectedDevAccount() {
        signIn(
            using: selectedDevAccount.userHandle,
            rememberedName: selectedDevAccount.displayName
        )
    }

    private func signIn(using userHandle: String?, rememberedName: String?) {
        errorMessage = nil
        isLoading = true

        Task {
            do {
                let resolvedUserHandle = try await authService.signInWithPasskey(userHandle: userHandle)

                await MainActor.run {
                    let finalUserID = resolvedUserHandle ?? userHandle
                    let displayName = rememberedName ?? Self.displayName(for: finalUserID)

                    session.completeAuthentication(
                        userID: finalUserID,
                        rememberedAccountName: displayName
                    )

                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    private static func displayName(for userID: String?) -> String? {
        switch userID {
        case "user_alice":
            return "Alice"
        case "user_bob":
            return "Bob"
        case "user_charlie":
            return "Charlie"
        default:
            return nil
        }
    }
}
