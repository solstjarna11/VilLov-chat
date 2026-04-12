//
//  StubPasskeyAuthenticator.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 26.3.2026.
//
// This keeps the auth flow compilable while we have not integrated real passkeys yet.

import Foundation

struct StubPasskeyAuthenticator: PasskeyAuthenticating {
    func signChallenge(
        _ challenge: PasskeyBeginResponse,
        userHandle: String?,
        deviceID: String?,
        deviceName: String?,
        platform: String?
    ) async throws -> PasskeyFinishRequest {
        PasskeyFinishRequest(
            challenge: challenge.challenge,
            credentialID: "stub-credential-id",
            userHandle: userHandle ?? challenge.userID,
            deviceID: deviceID,
            deviceName: deviceName,
            platform: platform,
            transports: "internal",
            clientDataJSON: "stub-client-data",
            authenticatorData: "stub-authenticator-data",
            signature: "stub-signature"
        )
    }
}
