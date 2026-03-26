//
//  AuthService.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 26.3.2026.
//

import Foundation

protocol PasskeyAuthenticating {
    func signChallenge(
        _ challenge: PasskeyBeginResponse,
        userHandle: String?
    ) async throws -> PasskeyFinishRequest
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

    func signInWithPasskey(userHandle: String? = nil) async throws -> String? {
        let beginResponse: PasskeyBeginResponse = try await apiClient.post(
            .passkeyBegin,
            body: PasskeyBeginRequest(),
            authenticated: false
        )

        let finishRequest = try await authenticator.signChallenge(
            beginResponse,
            userHandle: userHandle
        )

        let token: SessionToken = try await apiClient.post(
            .passkeyFinish,
            body: finishRequest,
            authenticated: false
        )

        tokenStore.setSessionToken(token)
        return finishRequest.userHandle
    }

    func signOut() {
        tokenStore.clear()
    }
}
