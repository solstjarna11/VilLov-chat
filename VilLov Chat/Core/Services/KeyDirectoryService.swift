//
//  KeyDirectoryService.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 26.3.2026.
//


import Foundation

@MainActor
final class KeyDirectoryService {
    private let apiClient: APIClient
    private let localKeyStore: LocalKeyStore
    private let identityTrustStore: IdentityTrustStore
    private let session: AppSession

    private let defaultUploadBatchSize = 50

    init(
        apiClient: APIClient,
        localKeyStore: LocalKeyStore,
        identityTrustStore: IdentityTrustStore,
        session: AppSession
    ) {
        self.apiClient = apiClient
        self.localKeyStore = localKeyStore
        self.identityTrustStore = identityTrustStore
        self.session = session
    }

    func fetchRecipientKeyBundle(for userID: String) async throws -> RecipientKeyBundle {
        let bundle: RecipientKeyBundle = try await apiClient.get(.keyBundle(userID: userID))
        try observeRemoteIdentity(userID: userID, identityKey: bundle.identityKey)
        return bundle
    }

    func uploadOwnKeyBundle(_ request: UploadKeyBundleRequest) async throws {
        let _: RecipientKeyBundle = try await apiClient.post(.uploadKeys, body: request)
    }

    func uploadKeyBundleIfNeeded(
        for userID: String,
        desiredOPKBatchSize: Int? = nil
    ) async throws {
        let request = try localKeyStore.uploadBundleRequest(
            for: userID,
            oneTimePrekeyCount: desiredOPKBatchSize ?? defaultUploadBatchSize
        )
        try await uploadOwnKeyBundle(request)
    }

    func observeRemoteIdentity(userID: String, identityKey: String) throws {
        guard let currentUserID = session.currentUserID else { return }

        let fingerprint = try IdentityFingerprint.generate(from: identityKey)

        _ = identityTrustStore.upsertIdentity(
            userID: userID,
            identityKey: identityKey,
            fingerprint: fingerprint,
            currentUserID: currentUserID
        )
    }
}
