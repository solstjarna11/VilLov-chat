//
//  StubPasskeyAuthenticator.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 26.3.2026.
//

import Foundation

struct StubPasskeyAuthenticator: PasskeyAuthenticating {
    private let dev = DevelopmentPasskeyAuthenticator(
        credentialStore: DevPasskeyCredentialStore()
    )

    func registerCredential(
        _ challenge: PasskeyRegistrationBeginResponse,
        userHandle: String?,
        deviceID: String?,
        deviceName: String?,
        platform: String?
    ) async throws -> PasskeyRegistrationFinishRequest {
        try await dev.registerCredential(
            challenge,
            userHandle: userHandle,
            deviceID: deviceID,
            deviceName: deviceName,
            platform: platform
        )
    }

    func signChallenge(
        _ challenge: PasskeyAssertionBeginResponse,
        userHandle: String?,
        deviceID: String?,
        deviceName: String?,
        platform: String?
    ) async throws -> PasskeyAssertionFinishRequest {
        try await dev.signChallenge(
            challenge,
            userHandle: userHandle,
            deviceID: deviceID,
            deviceName: deviceName,
            platform: platform
        )
    }
}
