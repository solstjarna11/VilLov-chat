//
//  KeyDirectoryService.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 26.3.2026.
//

import Foundation

struct OneTimePreKeyCountResponse: Codable, Equatable {
    let remaining: Int
}

@MainActor
final class KeyDirectoryService {
    private let apiClient: APIClient
    private let localKeyStore: LocalKeyStore
    private let identityTrustStore: IdentityTrustStore
    private let session: AppSession

    private let defaultUploadBatchSize = 50
    private let defaultReplenishThreshold = 10

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
        try observeRemoteIdentity(
            userID: userID,
            signingIdentityKey: bundle.identityKey,
            agreementIdentityKey: bundle.identityAgreementKey
        )
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

    func fetchOwnRemainingOPKCount() async throws -> Int {
        let response: OneTimePreKeyCountResponse = try await apiClient.get(.myOPKCount)
        return response.remaining
    }

    func replenishOPKsIfNeeded(
        for userID: String,
        threshold: Int = 10,
        batchSize: Int = 50
    ) async throws {
        let remaining = try await fetchOwnRemainingOPKCount()
        guard remaining < threshold else { return }

        let request = try localKeyStore.uploadBundleRequest(
            for: userID,
            oneTimePrekeyCount: batchSize
        )
        try await uploadOwnKeyBundle(request)
    }

    /// Ensure the authenticated user is messaging-ready before entering the app.
    /// If the backend has no OPKs yet, upload a full initial bundle.
    func ensureInitialKeyBundle(for userID: String) async throws {
        do {
            let remaining = try await fetchOwnRemainingOPKCount()
            if remaining > 0 {
                return
            }
        } catch let error as APIError {
            switch error {
            case .notFound:
                break
            default:
                throw error
            }
        } catch {
            throw error
        }

        let request = try localKeyStore.uploadBundleRequest(
            for: userID,
            oneTimePrekeyCount: defaultUploadBatchSize
        )
        try await uploadOwnKeyBundle(request)
    }

    func observeRemoteIdentity(
        userID: String,
        signingIdentityKey: String,
        agreementIdentityKey: String
    ) throws {
        guard let currentUserID = session.currentUserID else { return }

        let fingerprint = try IdentityFingerprint.generate(
            signingIdentityKeyBase64: signingIdentityKey,
            agreementIdentityKeyBase64: agreementIdentityKey
        )

        _ = identityTrustStore.upsertIdentity(
            userID: userID,
            signingIdentityKey: signingIdentityKey,
            agreementIdentityKey: agreementIdentityKey,
            fingerprint: fingerprint,
            currentUserID: currentUserID
        )
    }
}
