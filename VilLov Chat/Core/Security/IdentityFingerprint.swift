//
//  IdentityFingerprint.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 19.4.2026.
//


import Foundation
import CryptoKit

enum IdentityFingerprintError: LocalizedError {
    case invalidBase64IdentityKey

    var errorDescription: String? {
        switch self {
        case .invalidBase64IdentityKey:
            return "Identity key could not be decoded."
        }
    }
}

enum IdentityFingerprint {
    static func generate(from identityKeyBase64: String) throws -> String {
        guard let identityKeyData = Data(base64Encoded: identityKeyBase64) else {
            throw IdentityFingerprintError.invalidBase64IdentityKey
        }

        let digest = SHA256.hash(data: identityKeyData)
        let digestData = Data(digest)

        let prefix = digestData.prefix(15)
        let bytes = Array(prefix)

        var groups: [String] = []
        for chunkStart in stride(from: 0, to: bytes.count, by: 3) {
            let chunk = bytes[chunkStart..<min(chunkStart + 3, bytes.count)]
            let value = chunk.reduce(0) { partial, byte in
                (partial << 8) | Int(byte)
            } % 100_000
            groups.append(String(format: "%05d", value))
        }

        return groups.joined(separator: " ")
    }
}
