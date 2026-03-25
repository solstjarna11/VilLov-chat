//
//  MessageProviding.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//


import Foundation

protocol MessageProviding {
    func loadMessages(for conversation: Conversation) -> [Message]
}