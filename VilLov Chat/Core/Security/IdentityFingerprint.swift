//
//  IdentityFingerprint.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 19.4.2026.
//


import Foundation
import CryptoKit

enum IdentityFingerprintError: LocalizedError {
    case invalidBase64SigningIdentityKey
    case invalidBase64AgreementIdentityKey

    var errorDescription: String? {
        switch self {
        case .invalidBase64SigningIdentityKey:
            return "Signing identity key could not be decoded."
        case .invalidBase64AgreementIdentityKey:
            return "Agreement identity key could not be decoded."
        }
    }
}

enum IdentityFingerprint {
    static func generate(
        signingIdentityKeyBase64: String,
        agreementIdentityKeyBase64: String
    ) throws -> String {
        guard let signingKeyData = Data(base64Encoded: signingIdentityKeyBase64) else {
            throw IdentityFingerprintError.invalidBase64SigningIdentityKey
        }

        guard let agreementKeyData = Data(base64Encoded: agreementIdentityKeyBase64) else {
            throw IdentityFingerprintError.invalidBase64AgreementIdentityKey
        }

        var combined = Data()
        combined.append(Data("VilLovChat-IdentityFingerprint-v2".utf8))
        combined.append(signingKeyData)
        combined.append(Data([0x00]))
        combined.append(agreementKeyData)

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
