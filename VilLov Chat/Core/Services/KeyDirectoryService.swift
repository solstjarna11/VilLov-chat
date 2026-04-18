//
//  KeyDirectoryService.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 26.3.2026.
//


import Foundation

final class KeyDirectoryService {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchRecipientKeyBundle(for userID: String) async throws -> RecipientKeyBundle {
        try await apiClient.get(.keyBundle(userID: userID))
    }

    func uploadOwnKeyBundle(_ request: UploadKeyBundleRequest) async throws {
        let _: RecipientKeyBundle = try await apiClient.post(.uploadKeys, body: request)
    }

    func uploadDevelopmentKeyBundleIfNeeded(for userID: String) async throws {
        let request = UploadKeyBundleRequest(
            userID: userID,
            identityKey: "dev-identity-key-\(userID)",
            signedPrekey: "dev-signed-prekey-\(userID)",
            signedPrekeySignature: "dev-signed-prekey-signature-\(userID)",
            oneTimePrekey: "dev-onetime-prekey-\(userID)"
        )

        try await uploadOwnKeyBundle(request)
    }
}
