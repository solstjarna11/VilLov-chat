//
//  ConversationSecurityViewModel.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//


import Foundation
import Observation

@MainActor
@Observable
final class ConversationSecurityViewModel {
    var disappearingMessagesEnabled: Bool
    var selectedExpiration: MessageExpiration
    var refreshID = UUID()

    let conversation: Conversation
    let currentUserID: String

    private let identityTrustStore: IdentityTrustStore
    private let localKeyStore: LocalKeyStore

    init(
        conversation: Conversation,
        currentUserID: String,
        identityTrustStore: IdentityTrustStore,
        localKeyStore: LocalKeyStore,
        selectedExpiration: MessageExpiration = .oneDay
    ) {
        self.conversation = conversation
        self.currentUserID = currentUserID
        self.identityTrustStore = identityTrustStore
        self.localKeyStore = localKeyStore
        self.disappearingMessagesEnabled = conversation.disappearingEnabled
        self.selectedExpiration = selectedExpiration
    }
    
    func reload() {
        refreshID = UUID()
    }

    var storedIdentity: StoredIdentity? {
        _ = refreshID
        return identityTrustStore.identity(
            for: conversation.recipientUserID,
            currentUserID: currentUserID
        )
    }

    var trustState: ContactTrustState {
        storedIdentity?.trustState ?? .unverified
    }

    var verificationStatusText: String {
        switch trustState {
        case .verified:
            return "Verified"
        case .unverified:
            return "Not Verified"
        case .changed:
            return "Identity Changed"
        }
    }

    var trustStore: IdentityTrustStore {
        identityTrustStore
    }

    var keyStore: LocalKeyStore {
        localKeyStore
    }
}
