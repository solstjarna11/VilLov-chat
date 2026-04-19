//
//  SharedSafetyNumber.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 19.4.2026.
//


import Foundation
import CryptoKit

enum SharedSafetyNumberError: LocalizedError {
    case invalidLocalIdentityKey
    case invalidRemoteIdentityKey

    var errorDescription: String? {
        switch self {
        case .invalidLocalIdentityKey:
            return "Local identity key could not be decoded."
        case .invalidRemoteIdentityKey:
            return "Remote identity key could not be decoded."
        }
    }
}

enum SharedSafetyNumber {
    static func generate(
        localUserID: String,
        localIdentityKeyBase64: String,
        remoteUserID: String,
        remoteIdentityKeyBase64: String
    ) throws -> String {
        guard let localKeyData = Data(base64Encoded: localIdentityKeyBase64) else {
            throw SharedSafetyNumberError.invalidLocalIdentityKey
        }

        guard let remoteKeyData = Data(base64Encoded: remoteIdentityKeyBase64) else {
            throw SharedSafetyNumberError.invalidRemoteIdentityKey
        }

        let orderedPairs: [(String, Data)] = [
            (localUserID, localKeyData),
            (remoteUserID, remoteKeyData)
        ]
        .sorted { lhs, rhs in
            lhs.0 < rhs.0
        }

        var combined = Data()
        combined.append(Data("VilLovChat-SharedSafetyNumber-v1".utf8))

        for (userID, keyData) in orderedPairs {
            combined.append(Data(userID.utf8))
            combined.append(Data([0x00]))
            combined.append(keyData)
            combined.append(Data([0x00]))
        }

        let digest = SHA256.hash(data: combined)
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
