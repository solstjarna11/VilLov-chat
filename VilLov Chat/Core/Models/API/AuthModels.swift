//
//  SessionToken.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 26.3.2026.
//


import Foundation

struct SessionToken: Codable, Equatable {
    let accessToken: String
    let expiresAt: Date
}

struct PasskeyBeginRequest: Codable {
    init() {}
}

struct PasskeyBeginResponse: Codable, Equatable {
    let challenge: String
    let relyingPartyID: String
    let userID: String?
}

struct PasskeyFinishRequest: Codable, Equatable {
    let credentialID: String
    let clientDataJSON: String
    let authenticatorData: String
    let signature: String
    let userHandle: String?
}