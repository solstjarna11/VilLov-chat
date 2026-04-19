//
//  RatchetSession.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 19.4.2026.
//


import Foundation

struct RatchetSession: Codable, Equatable, Identifiable {
    let id: UUID
    let conversationID: UUID
    let localUserID: String
    let remoteUserID: String

    let remoteSigningIdentityKey: String
    let remoteAgreementIdentityKey: String

    let rootKey: Data
    let sendingChainKey: Data?
    let receivingChainKey: Data?

    let localRatchetPrivateKey: Data?
    let remoteRatchetPublicKey: Data?

    let sendMessageNumber: Int
    let receiveMessageNumber: Int
    let previousSendingChainLength: Int

    let createdAt: Date
    let updatedAt: Date
}