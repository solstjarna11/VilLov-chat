//
//  ConversationService.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 26.3.2026.
//
// This is the first real orchestration layer.

import Foundation

final class ConversationService: ConversationServicing {
    private let apiClient: APIClient
    private let keyDirectoryService: KeyDirectoryService
    private let relayService: RelayService
    private let e2eeEngine: E2EEEngine
    private let session: AppSession

    init(
        apiClient: APIClient,
        keyDirectoryService: KeyDirectoryService,
        relayService: RelayService,
        e2eeEngine: E2EEEngine,
        session: AppSession
    ) {
        self.apiClient = apiClient
        self.keyDirectoryService = keyDirectoryService
        self.relayService = relayService
        self.e2eeEngine = e2eeEngine
        self.session = session
    }

    func sendMessage(
        plaintext: String,
        to recipientUserID: String,
        conversationID: UUID
    ) async throws {
        let keyBundle = try await keyDirectoryService.fetchRecipientKeyBundle(for: recipientUserID)

        try await e2eeEngine.ensureSession(
            with: recipientUserID,
            bundle: keyBundle
        )

        let encrypted = try await e2eeEngine.encrypt(
            plaintext: plaintext,
            recipientBundle: keyBundle,
            conversationID: conversationID
        )

        let request = SendCiphertextRequest(
            recipientUserID: recipientUserID,
            messageID: UUID(),
            conversationID: conversationID,
            ciphertext: encrypted.ciphertext,
            header: encrypted.header,
            sentAt: Date()
        )

        try await relayService.send(request)
    }

    func fetchInbox() async throws -> [DecryptedEnvelopeMessage] {
        let result = try await fetchInboxResilient()

        if let firstFailure = result.failures.first {
            throw NSError(
                domain: "ConversationService",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey: """
                    Some messages could not be decrypted. \
                    First failure: \(firstFailure.reason)
                    """
                ]
            )
        }

        return result.messages
    }

    func fetchInboxResilient() async throws -> InboxRefreshResult {
        let envelopes = try await relayService.fetchInbox()

        var decryptedMessages: [DecryptedEnvelopeMessage] = []
        var failures: [InboxMessageFailure] = []

        for envelope in envelopes {
            do {
                let decrypted = try await e2eeEngine.decrypt(envelope: envelope)

                try keyDirectoryService.observeRemoteIdentity(
                    userID: decrypted.senderUserID,
                    signingIdentityKey: decrypted.senderSigningIdentityKey,
                    agreementIdentityKey: decrypted.senderAgreementIdentityKey
                )

                decryptedMessages.append(decrypted)

                do {
                    try await relayService.acknowledge(messageID: envelope.id)
                } catch {
                    failures.append(
                        InboxMessageFailure(
                            id: UUID(),
                            envelopeID: envelope.id,
                            senderUserID: envelope.senderUserID,
                            conversationID: envelope.conversationID,
                            reason: "Message decrypted but acknowledgement failed: \(error.localizedDescription)",
                            createdAt: envelope.createdAt
                        )
                    )
                }
            } catch {
                failures.append(
                    InboxMessageFailure(
                        id: UUID(),
                        envelopeID: envelope.id,
                        senderUserID: envelope.senderUserID,
                        conversationID: envelope.conversationID,
                        reason: classifyInboxFailure(error),
                        createdAt: envelope.createdAt
                    )
                )
            }
        }

        if let currentUserID = await MainActor.run(body: { session.currentUserID }) {
            try? await keyDirectoryService.replenishOPKsIfNeeded(
                for: currentUserID,
                threshold: 10,
                batchSize: 50
            )
        }

        return InboxRefreshResult(
            messages: decryptedMessages.sorted { $0.createdAt < $1.createdAt },
            failures: failures.sorted { $0.createdAt < $1.createdAt }
        )
    }

    func getOrCreateConversation(with recipientUserID: String) async throws -> UUID {
        let request = GetOrCreateConversationRequest(recipientUserID: recipientUserID)
        let response: GetOrCreateConversationResponse = try await apiClient.post(
            .getOrCreateConversation,
            body: request
        )
        return response.conversationID
    }

    private func classifyInboxFailure(_ error: Error) -> String {
        if let e2eeError = error as? E2EEError {
            switch e2eeError {
            case .missingRequiredLocalOneTimePrekey:
                return "Missing required local one-time prekey for bootstrap message."
            case .invalidSignature:
                return "Signature verification failed."
            case .invalidHeader:
                return "Message header is invalid."
            case .invalidCiphertext:
                return "Ciphertext is malformed."
            case .decryptionFailed:
                return "Ciphertext could not be decrypted with current session state."
            case .missingSessionBootstrapMaterial:
                return "Session bootstrap material is missing."
            case .invalidSenderIdentityKey:
                return "Sender signing identity key is invalid."
            case .invalidSenderIdentityAgreementKey:
                return "Sender agreement identity key is invalid."
            case .invalidEphemeralPublicKey:
                return "Bootstrap ephemeral key is invalid."
            case .noAuthenticatedUser:
                return "No authenticated user available for inbox decryption."
            case .missingConversationPeer:
                return "Conversation peer information is missing."
            case .invalidRecipientIdentityKey,
                 .invalidRecipientIdentityAgreementKey,
                 .invalidRecipientSignedPrekey,
                 .invalidRecipientSignedPrekeySignature,
                 .invalidRecipientOneTimePrekey:
                return "Recipient-side key material is invalid for this message flow."
            }
        }

        return error.localizedDescription
    }
}
