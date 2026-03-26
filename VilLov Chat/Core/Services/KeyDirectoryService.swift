//
//  KeyDirectoryService.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 26.3.2026.
//


import Foundation

final class KeyDirectoryService {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchRecipientKeyBundle(for userID: String) async throws -> RecipientKeyBundle {
        try await apiClient.get(.keyBundle(userID: userID))
    }
}