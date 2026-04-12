//
//  ConversationDirectoryService.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 12.4.2026.
//


import Foundation

final class ConversationDirectoryService {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchConversations() async throws -> [APIConversation] {
        try await apiClient.get(.conversations)
    }
}