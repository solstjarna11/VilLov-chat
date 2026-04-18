//
//  EmptyConversationProvider.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 26.3.2026.
//


import Foundation

struct EmptyConversationProvider: ConversationProviding {
    func loadConversations(for currentUserId: String?) -> [Conversation] {
        []
    }
}

