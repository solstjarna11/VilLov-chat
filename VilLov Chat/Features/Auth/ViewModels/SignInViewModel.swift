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

    private let authService: AuthService
    private let session: AppSession

    init(
        authService: AuthService,
        session: AppSession
    ) {
        self.authService = authService
        self.session = session
    }

    func signIn() {
        errorMessage = nil
        isLoading = true

        Task {
            do {
                try await authService.signInWithPasskey()

                await MainActor.run {
                    session.completeAuthentication()
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