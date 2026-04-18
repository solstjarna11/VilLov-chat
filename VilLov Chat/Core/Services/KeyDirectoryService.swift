//
//  KeyDirectoryService.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 26.3.2026.
//


import Foundation

final class KeyDirectoryService {
    private let apiClient: APIClient
    private let localKeyStore: LocalKeyStore

    init(
        apiClient: APIClient,
        localKeyStore: LocalKeyStore
    ) {
        self.apiClient = apiClient
        self.localKeyStore = localKeyStore
    }

    func fetchRecipientKeyBundle(for userID: String) async throws -> RecipientKeyBundle {
        try await apiClient.get(.keyBundle(userID: userID))
    }

    func uploadOwnKeyBundle(_ request: UploadKeyBundleRequest) async throws {
        let _: RecipientKeyBundle = try await apiClient.post(.uploadKeys, body: request)
    }

    func uploadDevelopmentKeyBundleIfNeeded(for userID: String) async throws {
        let request = try localKeyStore.uploadBundleRequest(for: userID)
        try await uploadOwnKeyBundle(request)
    }
}
