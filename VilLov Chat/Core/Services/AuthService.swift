//
//  AuthService.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 26.3.2026.
//

import Foundation

protocol PasskeyAuthenticating {
    func signChallenge(_ challenge: PasskeyBeginResponse) async throws -> PasskeyFinishRequest
}

@MainActor
final class AuthService {
    private let apiClient: APIClient
    private let tokenStore: AuthTokenStore
    private let authenticator: PasskeyAuthenticating

    init(
        apiClient: APIClient,
        tokenStore: AuthTokenStore,
        authenticator: PasskeyAuthenticating
    ) {
        self.apiClient = apiClient
        self.tokenStore = tokenStore
        self.authenticator = authenticator
    }

    func signInWithPasskey() async throws {
        let beginResponse: PasskeyBeginResponse = try await apiClient.post(
            .passkeyBegin,
            body: PasskeyBeginRequest(),
            authenticated: false
        )

        let finishRequest = try await authenticator.signChallenge(beginResponse)

        let token: SessionToken = try await apiClient.post(
            .passkeyFinish,
            body: finishRequest,
            authenticated: false
        )

        tokenStore.setSessionToken(token)
    }

    func signOut() {
        tokenStore.clear()
    }
}
