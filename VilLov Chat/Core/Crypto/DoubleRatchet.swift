//
//  DoubleRatchet.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 19.4.2026.
//


import Foundation
import CryptoKit

enum DoubleRatchet {
    private static let chainLabel = Data("VilLovChat-SymmetricChain-v1".utf8)

    static func deriveChainStep(from chainKey: Data) -> (nextChainKey: Data, messageKey: SymmetricKey) {
        let inputKey = SymmetricKey(data: chainKey)

        let expanded = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: inputKey,
            salt: Data(),
            info: chainLabel,
            outputByteCount: 64
        )

        let expandedData = expanded.withUnsafeBytes { Data($0) }
        let nextChainKey = expandedData.prefix(32)
        let messageKeyData = expandedData.suffix(32)

        return (
            nextChainKey: Data(nextChainKey),
            messageKey: SymmetricKey(data: messageKeyData)
        )
    }

    static func deriveInitialChainKey(
        rootKey: Data,
        label: String
    ) -> Data {
        let inputKey = SymmetricKey(data: rootKey)

        let derived = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: inputKey,
            salt: Data(),
            info: Data("VilLovChat-InitialChain-\(label)".utf8),
            outputByteCount: 32
        )

        return derived.withUnsafeBytes { Data($0) }
    }

    static func deriveRootStep(
        rootKey: Data,
        dhOutput: SharedSecret,
        senderLabel: String,
        receiverLabel: String
    ) -> (nextRootKey: Data, senderChainKey: Data, receiverChainKey: Data) {
        let dhData = dhOutput.withUnsafeBytes { Data($0) }
        let inputKey = SymmetricKey(data: dhData)

        let expanded = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: inputKey,
            salt: rootKey,
            info: Data("VilLovChat-DH-Ratchet-v1".utf8),
            outputByteCount: 96
        )

        let expandedData = expanded.withUnsafeBytes { Data($0) }
        let nextRootKey = Data(expandedData[0..<32])
        let senderSeed = Data(expandedData[32..<64])
        let receiverSeed = Data(expandedData[64..<96])

        let sendingChainKey = deriveInitialChainKey(rootKey: senderSeed, label: senderLabel)
        let receivingChainKey = deriveInitialChainKey(rootKey: receiverSeed, label: receiverLabel)

        return (
            nextRootKey: nextRootKey,
            senderChainKey: sendingChainKey,
            receiverChainKey: receivingChainKey
        )
    }
}
