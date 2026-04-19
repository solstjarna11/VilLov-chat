//
//  IdentityTrustStore.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 19.4.2026.
//


import Foundation

struct StoredIdentity: Codable, Equatable, Identifiable {
    var id: String { userID }

    let userID: String
    let identityKey: String
    let fingerprint: String
    let trustState: ContactTrustState
    let firstSeenAt: Date
    let lastSeenAt: Date
}

@MainActor
final class IdentityTrustStore {
    private let defaults: UserDefaults
    private let storageKeyPrefix = "identity_store_"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadAll(currentUserID: String) -> [StoredIdentity] {
        let key = storageKey(for: currentUserID)

        guard let data = defaults.data(forKey: key) else {
            return []
        }

        do {
            return try JSONDecoder().decode([StoredIdentity].self, from: data)
        } catch {
            return []
        }
    }

    func identity(for userID: String?, currentUserID: String) -> StoredIdentity? {
        guard let userID else { return nil }
        return loadAll(currentUserID: currentUserID).first(where: { $0.userID == userID })
    }

    @discardableResult
    func upsertIdentity(
        userID: String,
        identityKey: String,
        fingerprint: String,
        currentUserID: String
    ) -> ContactTrustState {
        var identities = loadAll(currentUserID: currentUserID)
        let now = Date()

        if let index = identities.firstIndex(where: { $0.userID == userID }) {
            let existing = identities[index]

            if existing.identityKey == identityKey {
                identities[index] = StoredIdentity(
                    userID: existing.userID,
                    identityKey: existing.identityKey,
                    fingerprint: existing.fingerprint,
                    trustState: existing.trustState,
                    firstSeenAt: existing.firstSeenAt,
                    lastSeenAt: now
                )
                saveAll(identities, currentUserID: currentUserID)
                return existing.trustState
            } else {
                let updated = StoredIdentity(
                    userID: userID,
                    identityKey: identityKey,
                    fingerprint: fingerprint,
                    trustState: .changed,
                    firstSeenAt: existing.firstSeenAt,
                    lastSeenAt: now
                )
                identities[index] = updated
                saveAll(identities, currentUserID: currentUserID)
                return .changed
            }
        } else {
            let newIdentity = StoredIdentity(
                userID: userID,
                identityKey: identityKey,
                fingerprint: fingerprint,
                trustState: .unverified,
                firstSeenAt: now,
                lastSeenAt: now
            )
            identities.append(newIdentity)
            saveAll(identities, currentUserID: currentUserID)
            return .unverified
        }
    }

    func markVerified(userID: String, currentUserID: String) {
        var identities = loadAll(currentUserID: currentUserID)

        guard let index = identities.firstIndex(where: { $0.userID == userID }) else { return }

        let existing = identities[index]
        identities[index] = StoredIdentity(
            userID: existing.userID,
            identityKey: existing.identityKey,
            fingerprint: existing.fingerprint,
            trustState: .verified,
            firstSeenAt: existing.firstSeenAt,
            lastSeenAt: Date()
        )

        saveAll(identities, currentUserID: currentUserID)
    }

    private func saveAll(_ identities: [StoredIdentity], currentUserID: String) {
        do {
            let data = try JSONEncoder().encode(identities)
            defaults.set(data, forKey: storageKey(for: currentUserID))
        } catch {
            return
        }
    }

    private func storageKey(for currentUserID: String) -> String {
        storageKeyPrefix + currentUserID
    }
}
