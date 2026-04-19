//
//  KeyBundleModels.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 26.3.2026.
//

import Foundation

struct OneTimePrekeyUpload: Codable, Equatable {
    let id: String
    let publicKey: String
}

struct RecipientKeyBundle: Codable, Equatable {
    let userID: String
    let identityKey: String              // signing identity public key
    let identityAgreementKey: String     // agreement identity public key
    let signedPrekey: String
    let signedPrekeySignature: String
    let oneTimePrekey: String?
    let oneTimePrekeyId: String?
}

struct UploadKeyBundleRequest: Codable, Equatable {
    let userID: String
    let identityKey: String              // signing identity public key
    let identityAgreementKey: String     // agreement identity public key
    let signedPrekey: String
    let signedPrekeySignature: String
    let oneTimePrekeys: [OneTimePrekeyUpload]
}

enum HandshakeMode: String, Codable, Equatable {
    case prekey
    case fallback
}
