//
//  RecipientKeyBundle.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 26.3.2026.
//


import Foundation

struct RecipientKeyBundle: Codable, Equatable {
    let userID: String
    let identityKey: String
    let signedPrekey: String
    let signedPrekeySignature: String
    let oneTimePrekey: String?
}