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
}