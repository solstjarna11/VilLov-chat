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
        userHandle: String?,
        deviceID: String?,
        deviceName: String?,
        platform: String?
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

    func signInWithPasskey(
        userHandle: String? = nil,
        deviceID: String? = nil,
        deviceName: String? = nil,
        platform: String? = "ios"
    ) async throws -> String? {
        let resolvedDeviceID = deviceID ?? userHandle.map { "device-\($0)-iphone" }

        let beginResponse: PasskeyBeginResponse = try await apiClient.post(
            .passkeyLoginBegin,
            body: PasskeyBeginRequest(
                userHandle: userHandle,
                deviceID: resolvedDeviceID
            ),
            authenticated: false
        )

        let finishRequest = try await authenticator.signChallenge(
            beginResponse,
            userHandle: userHandle,
            deviceID: resolvedDeviceID,
            deviceName: deviceName,
            platform: platform
        )

        let token: SessionToken = try await apiClient.post(
            .passkeyLoginFinish,
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
