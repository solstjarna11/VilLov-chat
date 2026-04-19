//
//  ContactVerificationViewModel.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//


import Foundation
import Observation

#if os(macOS)
import AppKit
#endif

#if os(iOS)
import UIKit
#endif

@MainActor
@Observable
final class ContactVerificationViewModel {
    let conversation: Conversation
    let currentUserID: String
    var refreshID = UUID()

    private let identityTrustStore: IdentityTrustStore
    private let localKeyStore: LocalKeyStore

    init(
        conversation: Conversation,
        currentUserID: String,
        identityTrustStore: IdentityTrustStore,
        localKeyStore: LocalKeyStore
    ) {
        self.conversation = conversation
        self.currentUserID = currentUserID
        self.identityTrustStore = identityTrustStore
        self.localKeyStore = localKeyStore
    }

    var storedIdentity: StoredIdentity? {
        _ = refreshID
        return identityTrustStore.identity(
            for: conversation.recipientUserID,
            currentUserID: currentUserID
        )
    }

    var statusTitle: String {
        switch storedIdentity?.trustState ?? .unverified {
        case .verified:
            return "This contact is verified"
        case .unverified:
            return "This contact is not verified"
        case .changed:
            return "This contact’s identity changed"
        }
    }

    var statusSystemImage: String {
        switch storedIdentity?.trustState ?? .unverified {
        case .verified:
            return "checkmark.shield.fill"
        case .unverified:
            return "exclamationmark.shield"
        case .changed:
            return "exclamationmark.triangle.fill"
        }
    }

    var safetyNumber: String {
        guard
            let remoteUserID = conversation.recipientUserID,
            let remoteIdentity = storedIdentity
        else {
            return "Unavailable"
        }

        do {
            let localIdentityKeyBase64 = try localKeyStore.identitySigningPublicKeyBase64(for: currentUserID)

            return try SharedSafetyNumber.generate(
                localUserID: currentUserID,
                localIdentityKeyBase64: localIdentityKeyBase64,
                remoteUserID: remoteUserID,
                remoteIdentityKeyBase64: remoteIdentity.identityKey
            )
        } catch {
            return "Unavailable"
        }
    }

    var qrCodeDescription: String {
        if storedIdentity == nil {
            return "No identity has been observed for this contact yet."
        }
        return "Compare this safety number with your contact while together in person."
    }

    var canMarkVerified: Bool {
        storedIdentity != nil && storedIdentity?.trustState != .verified
    }

    func markAsVerified() {
        guard let userID = conversation.recipientUserID else { return }
        identityTrustStore.markVerified(userID: userID, currentUserID: currentUserID)
        refreshID = UUID()
    }

    func copySafetyNumberToClipboard() {
        #if os(iOS)
        UIPasteboard.general.string = safetyNumber
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(safetyNumber, forType: .string)
        #endif
    }
}
