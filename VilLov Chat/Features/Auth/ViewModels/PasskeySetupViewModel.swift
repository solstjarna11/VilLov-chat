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

    init(
        mode: Mode,
        authService: AuthService,
        session: AppSession,
        userHandle: String? = nil,
        rememberedAccountName: String? = nil
    ) {
        self.mode = mode
        self.authService = authService
        self.session = session
        self.userHandle = userHandle
        self.rememberedAccountName = rememberedAccountName
    }

    func performPasskeyFlow() async {
        guard !isWorking else { return }

        isWorking = true
        errorMessage = nil

        do {
            let resolvedUserHandle: String?

            switch mode {
            case .registration:
                let registrationUserHandle = userHandle ?? "user_alice"
                resolvedUserHandle = try await authService.registerWithPasskey(
                    userHandle: registrationUserHandle,
                    displayName: rememberedAccountName
                )

            case .authentication:
                resolvedUserHandle = try await authService.signInWithPasskey(
                    userHandle: userHandle
                )
            }

            session.completeAuthentication(
                userID: resolvedUserHandle,
                rememberedAccountName: rememberedAccountName ?? resolvedUserHandle,
                isPasskeyConfigured: true
            )

            isWorking = false
        } catch {
            errorMessage = error.localizedDescription
            isWorking = false
        }
    }
}
