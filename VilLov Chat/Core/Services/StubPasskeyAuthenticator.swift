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
        userHandle: String?
    ) async throws -> PasskeyFinishRequest {
        PasskeyFinishRequest(
            credentialID: "stub-credential-id",
            clientDataJSON: "stub-client-data",
            authenticatorData: "stub-authenticator-data",
            signature: "stub-signature",
            userHandle: userHandle ?? challenge.userID
        )
    }
}
