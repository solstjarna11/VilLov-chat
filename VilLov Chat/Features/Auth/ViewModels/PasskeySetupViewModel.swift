//
//  PasskeySetupViewModel.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 17.4.2026.
//

import Foundation
import Observation

@MainActor
@Observable
final class PasskeySetupViewModel {
    enum Mode {
        case registration
        case authentication
    }

    let mode: Mode
    var isWorking = false
    var errorMessage: String?

    private let authService: AuthService
    private let session: AppSession
    private let userHandle: String?
    private let rememberedAccountName: String?
    private let rememberedAccountsStore: RememberedAccountsStore

    init(
        mode: Mode,
        authService: AuthService,
        session: AppSession,
        userHandle: String? = nil,
        rememberedAccountName: String? = nil,
        rememberedAccountsStore: RememberedAccountsStore? = nil
    ) {
        self.mode = mode
        self.authService = authService
        self.session = session
        self.userHandle = userHandle
        self.rememberedAccountName = rememberedAccountName
        self.rememberedAccountsStore = rememberedAccountsStore ?? RememberedAccountsStore()
    }

    func performPasskeyFlow() async {
        guard !isWorking else { return }

        isWorking = true
        errorMessage = nil

        do {
            let resolvedUserHandle: String?

            switch mode {
            case .registration:
                guard let registrationUserHandle = userHandle, !registrationUserHandle.isEmpty else {
                    errorMessage = "Missing account username."
                    isWorking = false
                    return
                }

                resolvedUserHandle = try await authService.registerWithPasskey(
                    userHandle: registrationUserHandle,
                    displayName: rememberedAccountName
                )

            case .authentication:
                resolvedUserHandle = try await authService.signInWithPasskey(
                    userHandle: userHandle
                )
            }

            let finalUserHandle = resolvedUserHandle ?? userHandle
            let finalDisplayName = rememberedAccountName ?? finalUserHandle ?? "Unknown"

            if let finalUserHandle {
                rememberedAccountsStore.upsertAccount(
                    userHandle: finalUserHandle,
                    displayName: finalDisplayName
                )
            }

            session.completeAuthentication(
                userID: finalUserHandle,
                rememberedAccountName: finalDisplayName,
                isPasskeyConfigured: true
            )

            isWorking = false
        } catch {
            errorMessage = error.localizedDescription
            isWorking = false
        }
    }
}
