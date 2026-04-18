//
//  EmptyMessageProvider.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 26.3.2026.
//


import Foundation

struct EmptyMessageProvider: MessageProviding {
    func loadMessages(for conversation: Conversation) -> [Message] {
        []
    }
}

