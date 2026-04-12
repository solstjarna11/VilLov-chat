//
//  ConversationListModels.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 12.4.2026.
//

import Foundation

struct APIConversation: Codable, Hashable {
    let conversationID: UUID
    let participantAUserID: String
    let participantBUserID: String
    let createdAt: Date
}
