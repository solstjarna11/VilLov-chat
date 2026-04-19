//
//  SignInViewModel.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 17.4.2026.
//

import Foundation
import Observation

@MainActor
@Observable
final class SignInViewModel {
    var isLoading = false
    var errorMessage: String?
    var showsAccountPicker = false
    var rememberedAccounts: [RememberedAccount] = []
    var selectedAccount: RememberedAccount?

    private let authService: AuthService
    private let session: AppSession
    private let rememberedAccountsStore: RememberedAccountsStore

    init(
        authService: AuthService,
        session: AppSession,
        rememberedAccountsStore: RememberedAccountsStore? = nil,
        keyDirectoryService: KeyDirectoryService
    ) {
        self.authService = authService
        self.session = session
        self.rememberedAccountsStore = rememberedAccountsStore ?? RememberedAccountsStore()

        self.rememberedAccounts = self.rememberedAccountsStore.loadAccounts()
        self.selectedAccount = self.rememberedAccounts.first
    }

    var rememberedAccountName: String? {
        rememberedAccounts.first?.displayName
    }

    var hasRememberedAccounts: Bool {
        !rememberedAccounts.isEmpty
    }

    func refreshRememberedAccounts() {
        rememberedAccounts = rememberedAccountsStore.loadAccounts()
        if selectedAccount == nil || !rememberedAccounts.contains(where: { $0.id == selectedAccount?.id }) {
            selectedAccount = rememberedAccounts.first
        }
    }

    func signInWithDefaultPasskey() {
        signIn(
            using: rememberedAccounts.first?.userHandle,
            rememberedName: rememberedAccounts.first?.displayName
        )
    }

    func signInWithRememberedAccount() {
        signIn(
            using: rememberedAccounts.first?.userHandle,
            rememberedName: rememberedAccounts.first?.displayName
        )
    }

    func signInWithSelectedAccount() {
        signIn(
            using: selectedAccount?.userHandle,
            rememberedName: selectedAccount?.displayName
        )
    }

    private func signIn(using userHandle: String?, rememberedName: String?) {
        errorMessage = nil
        isLoading = true

        Task {
            do {
                let resolvedUserHandle = try await authService.signInWithPasskey(userHandle: userHandle)

                let finalUserID = resolvedUserHandle ?? userHandle
                let finalDisplayName = rememberedName ?? finalUserID ?? "Unknown"

                if let finalUserID {
                    rememberedAccountsStore.upsertAccount(
                        userHandle: finalUserID,
                        displayName: finalDisplayName
                    )
                }

                await MainActor.run {
                    refreshRememberedAccounts()

                    session.completeAuthentication(
                        userID: finalUserID,
                        rememberedAccountName: finalDisplayName
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
}
