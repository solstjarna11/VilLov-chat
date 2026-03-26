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

    let conversation: Conversation

    init(
        conversation: Conversation,
        selectedExpiration: MessageExpiration = .oneDay
    ) {
        self.conversation = conversation
        self.disappearingMessagesEnabled = conversation.disappearingEnabled
        self.selectedExpiration = selectedExpiration
    }

    var verificationStatusText: String {
        conversation.isVerified ? "Verified" : "Not Verified"
    }
}
