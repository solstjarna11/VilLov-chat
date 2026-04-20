//
//  IdentityTrustModelTests.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 19.4.2026.
//


import Foundation
import Testing
import CryptoKit

@testable import VilLov_Chat

struct IdentityTrustModelTests {

    // MARK: - Helpers

    @MainActor
    private func makeStore() -> IdentityTrustStore {
        let suiteName = "IdentityTrustModelTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return IdentityTrustStore(defaults: defaults)
    }

    private func makeKeyPair() throws -> (signing: String, agreement: String) {
        let signing = Curve25519.Signing.PrivateKey()
            .publicKey
            .rawRepresentation
            .base64EncodedString()

        let agreement = Curve25519.KeyAgreement.PrivateKey()
            .publicKey
            .rawRepresentation
            .base64EncodedString()

        return (signing, agreement)
    }

    private func fingerprint(
        signing: String,
        agreement: String
    ) throws -> String {
        try IdentityFingerprint.generate(
            signingIdentityKeyBase64: signing,
            agreementIdentityKeyBase64: agreement
        )
    }

    // MARK: - Trust store behavior

    @Test
    @MainActor
    func first_observation_is_unverified() throws {
        let store = makeStore()
        let currentUserID = "alice"
        let remoteUserID = "bob"

        let keys = try makeKeyPair()
        let fp = try fingerprint(signing: keys.signing, agreement: keys.agreement)

        let trustState = store.upsertIdentity(
            userID: remoteUserID,
            signingIdentityKey: keys.signing,
            agreementIdentityKey: keys.agreement,
            fingerprint: fp,
            currentUserID: currentUserID
        )

        #expect(trustState == .unverified)

        let stored = store.identity(for: remoteUserID, currentUserID: currentUserID)
        #expect(stored != nil)
        #expect(stored?.trustState == .unverified)
        #expect(stored?.signingIdentityKey == keys.signing)
        #expect(stored?.agreementIdentityKey == keys.agreement)
        #expect(stored?.fingerprint == fp)
    }

    @Test
    @MainActor
    func no_key_change_preserves_existing_trust_state() throws {
        let store = makeStore()
        let currentUserID = "alice"
        let remoteUserID = "bob"

        let keys = try makeKeyPair()
        let fp = try fingerprint(signing: keys.signing, agreement: keys.agreement)

        _ = store.upsertIdentity(
            userID: remoteUserID,
            signingIdentityKey: keys.signing,
            agreementIdentityKey: keys.agreement,
            fingerprint: fp,
            currentUserID: currentUserID
        )

        store.markVerified(userID: remoteUserID, currentUserID: currentUserID)

        let trustState = store.upsertIdentity(
            userID: remoteUserID,
            signingIdentityKey: keys.signing,
            agreementIdentityKey: keys.agreement,
            fingerprint: fp,
            currentUserID: currentUserID
        )

        #expect(trustState == .verified)

        let stored = store.identity(for: remoteUserID, currentUserID: currentUserID)
        #expect(stored?.trustState == .verified)
        #expect(stored?.fingerprint == fp)
    }

    @Test
    @MainActor
    func signing_key_change_sets_changed() throws {
        let store = makeStore()
        let currentUserID = "alice"
        let remoteUserID = "bob"

        let original = try makeKeyPair()
        let originalFingerprint = try fingerprint(
            signing: original.signing,
            agreement: original.agreement
        )

        _ = store.upsertIdentity(
            userID: remoteUserID,
            signingIdentityKey: original.signing,
            agreementIdentityKey: original.agreement,
            fingerprint: originalFingerprint,
            currentUserID: currentUserID
        )

        store.markVerified(userID: remoteUserID, currentUserID: currentUserID)

        let changedSigning = try makeKeyPair()
        let changedFingerprint = try fingerprint(
            signing: changedSigning.signing,
            agreement: original.agreement
        )

        let trustState = store.upsertIdentity(
            userID: remoteUserID,
            signingIdentityKey: changedSigning.signing,
            agreementIdentityKey: original.agreement,
            fingerprint: changedFingerprint,
            currentUserID: currentUserID
        )

        #expect(trustState == .changed)

        let stored = store.identity(for: remoteUserID, currentUserID: currentUserID)
        #expect(stored?.trustState == .changed)
        #expect(stored?.signingIdentityKey == changedSigning.signing)
        #expect(stored?.agreementIdentityKey == original.agreement)
        #expect(stored?.fingerprint == changedFingerprint)
    }

    @Test
    @MainActor
    func agreement_key_change_sets_changed() throws {
        let store = makeStore()
        let currentUserID = "alice"
        let remoteUserID = "bob"

        let original = try makeKeyPair()
        let originalFingerprint = try fingerprint(
            signing: original.signing,
            agreement: original.agreement
        )

        _ = store.upsertIdentity(
            userID: remoteUserID,
            signingIdentityKey: original.signing,
            agreementIdentityKey: original.agreement,
            fingerprint: originalFingerprint,
            currentUserID: currentUserID
        )

        store.markVerified(userID: remoteUserID, currentUserID: currentUserID)

        let changedAgreement = try makeKeyPair()
        let changedFingerprint = try fingerprint(
            signing: original.signing,
            agreement: changedAgreement.agreement
        )

        let trustState = store.upsertIdentity(
            userID: remoteUserID,
            signingIdentityKey: original.signing,
            agreementIdentityKey: changedAgreement.agreement,
            fingerprint: changedFingerprint,
            currentUserID: currentUserID
        )

        #expect(trustState == .changed)

        let stored = store.identity(for: remoteUserID, currentUserID: currentUserID)
        #expect(stored?.trustState == .changed)
        #expect(stored?.signingIdentityKey == original.signing)
        #expect(stored?.agreementIdentityKey == changedAgreement.agreement)
        #expect(stored?.fingerprint == changedFingerprint)
    }

    @Test
    @MainActor
    func changing_both_keys_sets_changed() throws {
        let store = makeStore()
        let currentUserID = "alice"
        let remoteUserID = "bob"

        let original = try makeKeyPair()
        let originalFingerprint = try fingerprint(
            signing: original.signing,
            agreement: original.agreement
        )

        _ = store.upsertIdentity(
            userID: remoteUserID,
            signingIdentityKey: original.signing,
            agreementIdentityKey: original.agreement,
            fingerprint: originalFingerprint,
            currentUserID: currentUserID
        )

        store.markVerified(userID: remoteUserID, currentUserID: currentUserID)

        let replacement = try makeKeyPair()
        let replacementFingerprint = try fingerprint(
            signing: replacement.signing,
            agreement: replacement.agreement
        )

        let trustState = store.upsertIdentity(
            userID: remoteUserID,
            signingIdentityKey: replacement.signing,
            agreementIdentityKey: replacement.agreement,
            fingerprint: replacementFingerprint,
            currentUserID: currentUserID
        )

        #expect(trustState == .changed)

        let stored = store.identity(for: remoteUserID, currentUserID: currentUserID)
        #expect(stored?.trustState == .changed)
        #expect(stored?.signingIdentityKey == replacement.signing)
        #expect(stored?.agreementIdentityKey == replacement.agreement)
        #expect(stored?.fingerprint == replacementFingerprint)
    }

    @Test
    @MainActor
    func verification_marks_identity_verified() throws {
        let store = makeStore()
        let currentUserID = "alice"
        let remoteUserID = "bob"

        let keys = try makeKeyPair()
        let fp = try fingerprint(signing: keys.signing, agreement: keys.agreement)

        _ = store.upsertIdentity(
            userID: remoteUserID,
            signingIdentityKey: keys.signing,
            agreementIdentityKey: keys.agreement,
            fingerprint: fp,
            currentUserID: currentUserID
        )

        store.markVerified(userID: remoteUserID, currentUserID: currentUserID)

        let stored = store.identity(for: remoteUserID, currentUserID: currentUserID)
        #expect(stored?.trustState == .verified)
    }

    // MARK: - Fingerprint behavior

    @Test
    func fingerprint_changes_when_signing_key_changes() throws {
        let base = try makeKeyPair()
        let changedSigning = try makeKeyPair()

        let fp1 = try fingerprint(
            signing: base.signing,
            agreement: base.agreement
        )

        let fp2 = try fingerprint(
            signing: changedSigning.signing,
            agreement: base.agreement
        )

        #expect(fp1 != fp2)
    }

    @Test
    func fingerprint_changes_when_agreement_key_changes() throws {
        let base = try makeKeyPair()
        let changedAgreement = try makeKeyPair()

        let fp1 = try fingerprint(
            signing: base.signing,
            agreement: base.agreement
        )

        let fp2 = try fingerprint(
            signing: base.signing,
            agreement: changedAgreement.agreement
        )

        #expect(fp1 != fp2)
    }

    @Test
    func fingerprint_is_stable_for_same_key_pair() throws {
        let keys = try makeKeyPair()

        let fp1 = try fingerprint(
            signing: keys.signing,
            agreement: keys.agreement
        )

        let fp2 = try fingerprint(
            signing: keys.signing,
            agreement: keys.agreement
        )

        #expect(fp1 == fp2)
    }

    // MARK: - Shared safety number behavior

    @Test
    func safety_number_is_symmetric_between_participants() throws {
        let alice = try makeKeyPair()
        let bob = try makeKeyPair()

        let aToB = try SharedSafetyNumber.generate(
            localUserID: "alice",
            localSigningIdentityKeyBase64: alice.signing,
            localAgreementIdentityKeyBase64: alice.agreement,
            remoteUserID: "bob",
            remoteSigningIdentityKeyBase64: bob.signing,
            remoteAgreementIdentityKeyBase64: bob.agreement
        )

        let bToA = try SharedSafetyNumber.generate(
            localUserID: "bob",
            localSigningIdentityKeyBase64: bob.signing,
            localAgreementIdentityKeyBase64: bob.agreement,
            remoteUserID: "alice",
            remoteSigningIdentityKeyBase64: alice.signing,
            remoteAgreementIdentityKeyBase64: alice.agreement
        )

        #expect(aToB == bToA)
    }

    @Test
    func safety_number_changes_when_remote_signing_key_changes() throws {
        let alice = try makeKeyPair()
        let bob = try makeKeyPair()
        let bobChangedSigning = try makeKeyPair()

        let original = try SharedSafetyNumber.generate(
            localUserID: "alice",
            localSigningIdentityKeyBase64: alice.signing,
            localAgreementIdentityKeyBase64: alice.agreement,
            remoteUserID: "bob",
            remoteSigningIdentityKeyBase64: bob.signing,
            remoteAgreementIdentityKeyBase64: bob.agreement
        )

        let changed = try SharedSafetyNumber.generate(
            localUserID: "alice",
            localSigningIdentityKeyBase64: alice.signing,
            localAgreementIdentityKeyBase64: alice.agreement,
            remoteUserID: "bob",
            remoteSigningIdentityKeyBase64: bobChangedSigning.signing,
            remoteAgreementIdentityKeyBase64: bob.agreement
        )

        #expect(original != changed)
    }

    @Test
    func safety_number_changes_when_remote_agreement_key_changes() throws {
        let alice = try makeKeyPair()
        let bob = try makeKeyPair()
        let bobChangedAgreement = try makeKeyPair()

        let original = try SharedSafetyNumber.generate(
            localUserID: "alice",
            localSigningIdentityKeyBase64: alice.signing,
            localAgreementIdentityKeyBase64: alice.agreement,
            remoteUserID: "bob",
            remoteSigningIdentityKeyBase64: bob.signing,
            remoteAgreementIdentityKeyBase64: bob.agreement
        )

        let changed = try SharedSafetyNumber.generate(
            localUserID: "alice",
            localSigningIdentityKeyBase64: alice.signing,
            localAgreementIdentityKeyBase64: alice.agreement,
            remoteUserID: "bob",
            remoteSigningIdentityKeyBase64: bob.signing,
            remoteAgreementIdentityKeyBase64: bobChangedAgreement.agreement
        )

        #expect(original != changed)
    }

    @Test
    func safety_number_changes_when_local_agreement_key_changes() throws {
        let alice = try makeKeyPair()
        let aliceChangedAgreement = try makeKeyPair()
        let bob = try makeKeyPair()

        let original = try SharedSafetyNumber.generate(
            localUserID: "alice",
            localSigningIdentityKeyBase64: alice.signing,
            localAgreementIdentityKeyBase64: alice.agreement,
            remoteUserID: "bob",
            remoteSigningIdentityKeyBase64: bob.signing,
            remoteAgreementIdentityKeyBase64: bob.agreement
        )

        let changed = try SharedSafetyNumber.generate(
            localUserID: "alice",
            localSigningIdentityKeyBase64: alice.signing,
            localAgreementIdentityKeyBase64: aliceChangedAgreement.agreement,
            remoteUserID: "bob",
            remoteSigningIdentityKeyBase64: bob.signing,
            remoteAgreementIdentityKeyBase64: bob.agreement
        )

        #expect(original != changed)
    }

    @Test
    func safety_number_is_stable_for_same_inputs() throws {
        let alice = try makeKeyPair()
        let bob = try makeKeyPair()

        let first = try SharedSafetyNumber.generate(
            localUserID: "alice",
            localSigningIdentityKeyBase64: alice.signing,
            localAgreementIdentityKeyBase64: alice.agreement,
            remoteUserID: "bob",
            remoteSigningIdentityKeyBase64: bob.signing,
            remoteAgreementIdentityKeyBase64: bob.agreement
        )

        let second = try SharedSafetyNumber.generate(
            localUserID: "alice",
            localSigningIdentityKeyBase64: alice.signing,
            localAgreementIdentityKeyBase64: alice.agreement,
            remoteUserID: "bob",
            remoteSigningIdentityKeyBase64: bob.signing,
            remoteAgreementIdentityKeyBase64: bob.agreement
        )

        #expect(first == second)
    }
}
