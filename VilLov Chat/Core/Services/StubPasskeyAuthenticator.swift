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
        let resolvedUserHandle = userHandle ?? challenge.userID ?? "user_alice"
        let credentialID = "credential-\(resolvedUserHandle)-primary"

        return PasskeyFinishRequest(
            challenge: challenge.challenge,
            credentialID: credentialID,
            userHandle: resolvedUserHandle,
            deviceID: deviceID ?? "device-\(resolvedUserHandle)-iphone",
            deviceName: deviceName ?? "\(resolvedUserHandle) iPhone",
            platform: platform ?? "ios",
            transports: "internal",
            clientDataJSON: "stub-client-data",
            authenticatorData: "stub-authenticator-data",
            signature: "stub-signature"
        )
    }
}
