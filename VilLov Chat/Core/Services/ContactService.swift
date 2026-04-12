//
//  ContactService.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 12.4.2026.
//


import Foundation

final class ContactService {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchContacts() async throws -> [APIContact] {
        try await apiClient.get(.contacts)
    }
}