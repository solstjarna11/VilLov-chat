//
//  DevelopmentPasskeyAuthenticator.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 17.4.2026.
//

import Foundation
import CryptoKit

enum DevelopmentPasskeyError: Error {
    case invalidChallenge
    case missingCredential
    case invalidStoredKey
    case serializationFailed
}

private struct DevClientData: Codable {
    let type: String
    let challenge: String
    let origin: String
    let crossOrigin: Bool
}

private struct DevAttestationObject: Codable {
    let format: String
    let credentialID: String
    let publicKey: String
    let signCount: UInt32
}

private struct DevAuthenticatorData: Codable {
    let rpID: String
    let signCount: UInt32
    let userPresent: Bool
    let userVerified: Bool
}

@MainActor
final class DevelopmentPasskeyAuthenticator: PasskeyAuthenticating {
    private let credentialStore: DevPasskeyCredentialStore
    private let origin: String

    init(
        credentialStore: DevPasskeyCredentialStore,
        origin: String = "https://auth.villovchat.com"
    ) {
        self.credentialStore = credentialStore
        self.origin = origin
    }

    func registerCredential(
        _ challenge: PasskeyRegistrationBeginResponse,
        userHandle: String?,
        deviceID: String?,
        deviceName: String?,
        platform: String?
    ) async throws -> PasskeyRegistrationFinishRequest {
        let resolvedUserHandle = userHandle ?? challenge.userID
        guard Data(base64URLEncoded: challenge.challenge) != nil else {
            throw DevelopmentPasskeyError.invalidChallenge
        }

        let privateKey = P256.Signing.PrivateKey()
        let publicKey = privateKey.publicKey

        let credentialIDData = randomCredentialID()
        let credentialID = credentialIDData.base64URLEncodedString()

        let credential = DevPasskeyCredentialRecord(
            userHandle: resolvedUserHandle,
            credentialID: credentialID,
            privateKeyRawRepresentation: privateKey.rawRepresentation,
            publicKeyRawRepresentation: publicKey.x963Representation,
            signCount: 0
        )
        try credentialStore.saveCredential(credential)

        let clientData = DevClientData(
            type: "webauthn.create",
            challenge: challenge.challenge,
            origin: origin,
            crossOrigin: false
        )

        let attestationObject = DevAttestationObject(
            format: "dev-passkey-v1",
            credentialID: credentialID,
            publicKey: publicKey.x963Representation.base64URLEncodedString(),
            signCount: 0
        )

        let clientDataJSON = try jsonData(from: clientData)
        let attestationData = try jsonData(from: attestationObject)

        return PasskeyRegistrationFinishRequest(
            challenge: challenge.challenge,
            credentialID: credentialID,
            userHandle: resolvedUserHandle,
            deviceID: deviceID ?? "device-\(resolvedUserHandle)-iphone",
            deviceName: deviceName ?? "\(resolvedUserHandle) iPhone",
            platform: platform ?? "ios",
            transports: ["internal"],
            clientDataJSON: clientDataJSON.base64URLEncodedString(),
            attestationObject: attestationData.base64URLEncodedString()
        )
    }

    func signChallenge(
        _ challenge: PasskeyAssertionBeginResponse,
        userHandle: String?,
        deviceID: String?,
        deviceName: String?,
        platform: String?
    ) async throws -> PasskeyAssertionFinishRequest {
        guard let resolvedUserHandle = userHandle ?? challenge.userID else {
            throw DevelopmentPasskeyError.missingCredential
        }

        guard Data(base64URLEncoded: challenge.challenge) != nil else {
            throw DevelopmentPasskeyError.invalidChallenge
        }

        guard let storedCredential = try credentialStore.loadCredential(for: resolvedUserHandle) else {
            throw DevelopmentPasskeyError.missingCredential
        }

        let privateKey: P256.Signing.PrivateKey
        do {
            privateKey = try P256.Signing.PrivateKey(rawRepresentation: storedCredential.privateKeyRawRepresentation)
        } catch {
            throw DevelopmentPasskeyError.invalidStoredKey
        }

        let nextSignCount = storedCredential.signCount + 1

        let clientData = DevClientData(
            type: "webauthn.get",
            challenge: challenge.challenge,
            origin: origin,
            crossOrigin: false
        )

        let authenticatorData = DevAuthenticatorData(
            rpID: challenge.relyingPartyID,
            signCount: nextSignCount,
            userPresent: true,
            userVerified: true
        )

        let clientDataJSON = try jsonData(from: clientData)
        let authenticatorDataJSON = try jsonData(from: authenticatorData)

        var signatureInput = Data()
        signatureInput.append(authenticatorDataJSON)
        signatureInput.append(clientDataJSON)

        let signature = try privateKey.signature(for: signatureInput)

        try credentialStore.updateSignCount(for: resolvedUserHandle, signCount: nextSignCount)

        return PasskeyAssertionFinishRequest(
            challenge: challenge.challenge,
            credentialID: storedCredential.credentialID,
            userHandle: resolvedUserHandle,
            deviceID: deviceID ?? "device-\(resolvedUserHandle)-iphone",
            deviceName: deviceName ?? "\(resolvedUserHandle) iPhone",
            platform: platform ?? "ios",
            transports: ["internal"],
            clientDataJSON: clientDataJSON.base64URLEncodedString(),
            authenticatorData: authenticatorDataJSON.base64URLEncodedString(),
            signature: signature.derRepresentation.base64URLEncodedString()
        )
    }

    private func randomCredentialID() -> Data {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes)
    }

    private func jsonData<T: Encodable>(from value: T) throws -> Data {
        do {
            return try JSONEncoder().encode(value)
        } catch {
            throw DevelopmentPasskeyError.serializationFailed
        }
    }
}

