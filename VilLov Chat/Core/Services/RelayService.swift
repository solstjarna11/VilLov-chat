//
//  RelayService.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 26.3.2026.
//

import Foundation

final class RelayService {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func send(_ request: SendCiphertextRequest) async throws {
        try await apiClient.postEmpty(.sendMessage, body: request)
    }

    func fetchInbox() async throws -> [CiphertextEnvelope] {
        try await apiClient.get(.inbox)
    }

    func acknowledge(messageID: UUID) async throws {
        try await apiClient.postEmpty(
            .ackMessage,
            body: MessageAckRequest(messageID: messageID)
        )
    }

    func delete(messageID: UUID) async throws {
        try await apiClient.postEmpty(
            .deleteMessage,
            body: MessageDeleteRequest(messageID: messageID)
        )
    }
}
