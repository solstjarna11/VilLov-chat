//
//  CoreModels.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 26.3.2026.
//

import Foundation

struct GetOrCreateConversationRequest: Codable {
    let recipientUserID: String
}

struct GetOrCreateConversationResponse: Codable {
    let conversationID: UUID
}
