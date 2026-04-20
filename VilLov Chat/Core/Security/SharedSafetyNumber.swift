//
//  SharedSafetyNumber.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 19.4.2026.
//


import Foundation
import CryptoKit

enum SharedSafetyNumberError: LocalizedError {
    case invalidLocalSigningIdentityKey
    case invalidLocalAgreementIdentityKey
    case invalidRemoteSigningIdentityKey
    case invalidRemoteAgreementIdentityKey

    var errorDescription: String? {
        switch self {
        case .invalidLocalSigningIdentityKey:
            return "Local signing identity key could not be decoded."
        case .invalidLocalAgreementIdentityKey:
            return "Local agreement identity key could not be decoded."
        case .invalidRemoteSigningIdentityKey:
            return "Remote signing identity key could not be decoded."
        case .invalidRemoteAgreementIdentityKey:
            return "Remote agreement identity key could not be decoded."
        }
    }
}

enum SharedSafetyNumber {
    static func generate(
        localUserID: String,
        localSigningIdentityKeyBase64: String,
        localAgreementIdentityKeyBase64: String,
        remoteUserID: String,
        remoteSigningIdentityKeyBase64: String,
        remoteAgreementIdentityKeyBase64: String
    ) throws -> String {
        guard let localSigningKeyData = Data(base64Encoded: localSigningIdentityKeyBase64) else {
            throw SharedSafetyNumberError.invalidLocalSigningIdentityKey
        }

        guard let localAgreementKeyData = Data(base64Encoded: localAgreementIdentityKeyBase64) else {
            throw SharedSafetyNumberError.invalidLocalAgreementIdentityKey
        }

        guard let remoteSigningKeyData = Data(base64Encoded: remoteSigningIdentityKeyBase64) else {
            throw SharedSafetyNumberError.invalidRemoteSigningIdentityKey
        }

        guard let remoteAgreementKeyData = Data(base64Encoded: remoteAgreementIdentityKeyBase64) else {
            throw SharedSafetyNumberError.invalidRemoteAgreementIdentityKey
        }

        let orderedPairs: [(String, Data, Data)] = [
            (localUserID, localSigningKeyData, localAgreementKeyData),
            (remoteUserID, remoteSigningKeyData, remoteAgreementKeyData)
        ]
        .sorted { lhs, rhs in
            lhs.0 < rhs.0
        }

        var combined = Data()
        combined.append(Data("VilLovChat-SharedSafetyNumber-v2".utf8))

        for (userID, signingKeyData, agreementKeyData) in orderedPairs {
            combined.append(Data(userID.utf8))
            combined.append(Data([0x00]))
            combined.append(signingKeyData)
            combined.append(Data([0x00]))
            combined.append(agreementKeyData)
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
