//
//  ApplePasskeyAuthenticator.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 12.4.2026.
//

import Foundation
import AuthenticationServices
#if os(iOS)
import UIKit
#endif

enum PasskeyAuthError: Error {
    case invalidChallenge
    case invalidResponse
    case userCancelled
}

@MainActor
final class ApplePasskeyAuthenticator: NSObject, PasskeyAuthenticating {
    private var continuation: CheckedContinuation<ASAuthorization, Error>?

    func registerCredential(
        _ challenge: PasskeyRegistrationBeginResponse,
        userHandle: String?,
        deviceID: String?,
        deviceName: String?,
        platform: String?
    ) async throws -> PasskeyRegistrationFinishRequest {
        let rpID = challenge.relyingPartyID
        let resolvedUserHandle = userHandle ?? challenge.userID
        guard
            let challengeData = Data(base64URLEncoded: challenge.challenge),
            let userIDData = resolvedUserHandle.data(using: .utf8)
        else {
            throw PasskeyAuthError.invalidChallenge
        }

        let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: rpID)
        let request = provider.createCredentialRegistrationRequest(
            challenge: challengeData,
            name: challenge.userName,
            userID: userIDData
        )
        request.displayName = challenge.displayName

        let authorization = try await performAuthorization(request: request)

        guard
            let registration = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialRegistration,
            let rawAttestationObject = registration.rawAttestationObject
        else {
            throw PasskeyAuthError.invalidResponse
        }

        return PasskeyRegistrationFinishRequest(
            challenge: challenge.challenge,
            credentialID: registration.credentialID.base64URLEncodedString(),
            userHandle: resolvedUserHandle,
            deviceID: deviceID ?? "device-\(resolvedUserHandle)-iphone",
            deviceName: deviceName ?? "\(resolvedUserHandle) iPhone",
            platform: platform ?? "ios",
            transports: ["internal"],
            clientDataJSON: registration.rawClientDataJSON.base64URLEncodedString(),
            attestationObject: rawAttestationObject.base64URLEncodedString()
        )
    }

    func signChallenge(
        _ challenge: PasskeyAssertionBeginResponse,
        userHandle: String?,
        deviceID: String?,
        deviceName: String?,
        platform: String?
    ) async throws -> PasskeyAssertionFinishRequest {
        let rpID = challenge.relyingPartyID
        guard let challengeData = Data(base64URLEncoded: challenge.challenge) else {
            throw PasskeyAuthError.invalidChallenge
        }

        let resolvedUserHandle = userHandle ?? challenge.userID

        let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: rpID)
        let request = provider.createCredentialAssertionRequest(challenge: challengeData)

        let authorization = try await performAuthorization(request: request)

        guard let assertion = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialAssertion else {
            throw PasskeyAuthError.invalidResponse
        }

        let returnedUserHandle = assertion.userID.flatMap { String(data: $0, encoding: .utf8) } ?? resolvedUserHandle

        return PasskeyAssertionFinishRequest(
            challenge: challenge.challenge,
            credentialID: assertion.credentialID.base64URLEncodedString(),
            userHandle: returnedUserHandle,
            deviceID: deviceID ?? returnedUserHandle.map { "device-\($0)-iphone" },
            deviceName: deviceName ?? returnedUserHandle.map { "\($0) iPhone" },
            platform: platform ?? "ios",
            transports: ["internal"],
            clientDataJSON: assertion.rawClientDataJSON.base64URLEncodedString(),
            authenticatorData: assertion.rawAuthenticatorData.base64URLEncodedString(),
            signature: assertion.signature.base64URLEncodedString()
        )
    }

    private func performAuthorization(request: ASAuthorizationRequest) async throws -> ASAuthorization {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }
}

extension ApplePasskeyAuthenticator: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        continuation?.resume(returning: authorization)
        continuation = nil
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}

extension ApplePasskeyAuthenticator: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        #if os(iOS)
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow } ?? UIWindow()
        #else
        return ASPresentationAnchor()
        #endif
    }
}
