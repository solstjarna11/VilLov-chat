//
//  AuthService.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 26.3.2026.
//

import Foundation

protocol PasskeyAuthenticating {
    func registerCredential(
        _ challenge: PasskeyRegistrationBeginResponse,
        userHandle: String?,
        deviceID: String?,
        deviceName: String?,
        platform: String?
    ) async throws -> PasskeyRegistrationFinishRequest

    func signChallenge(
        _ challenge: PasskeyAssertionBeginResponse,
        userHandle: String?,
        deviceID: String?,
        deviceName: String?,
        platform: String?
    ) async throws -> PasskeyAssertionFinishRequest
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

    func registerWithPasskey(
        userHandle: String,
        displayName: String? = nil,
        deviceID: String? = nil,
        deviceName: String? = nil,
        platform: String? = "ios"
    ) async throws -> String {
        let resolvedDeviceID = deviceID ?? "device-\(userHandle)-iphone"

        let begin: PasskeyRegistrationBeginResponse = try await apiClient.post(
            .passkeyRegisterBegin,
            body: PasskeyBeginRequest(
                userHandle: userHandle,
                deviceID: resolvedDeviceID,
                displayName: displayName
            ),
            authenticated: false
        )

        let finish = try await authenticator.registerCredential(
            begin,
            userHandle: userHandle,
            deviceID: resolvedDeviceID,
            deviceName: deviceName,
            platform: platform
        )

        let token: SessionToken = try await apiClient.post(
            .passkeyRegisterFinish,
            body: finish,
            authenticated: false
        )

        tokenStore.setSessionToken(token)
        return userHandle
    }

    func signInWithPasskey(
        userHandle: String? = nil,
        deviceID: String? = nil,
        deviceName: String? = nil,
        platform: String? = "ios"
    ) async throws -> String? {
        let resolvedDeviceID = deviceID ?? userHandle.map { "device-\($0)-iphone" }

        let begin: PasskeyAssertionBeginResponse = try await apiClient.post(
            .passkeyLoginBegin,
            body: PasskeyBeginRequest(
                userHandle: userHandle,
                deviceID: resolvedDeviceID,
                displayName: nil
            ),
            authenticated: false
        )

        let finish = try await authenticator.signChallenge(
            begin,
            userHandle: userHandle,
            deviceID: resolvedDeviceID,
            deviceName: deviceName,
            platform: platform
        )

        let token: SessionToken = try await apiClient.post(
            .passkeyLoginFinish,
            body: finish,
            authenticated: false
        )

        tokenStore.setSessionToken(token)
        return finish.userHandle
    }

    func signOut() {
        tokenStore.clear()
    }
}
