//
//  AuthModels.swift
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
    let userHandle: String?
    let deviceID: String?

    init(userHandle: String? = nil, deviceID: String? = nil) {
        self.userHandle = userHandle
        self.deviceID = deviceID
    }
}

struct PasskeyBeginResponse: Codable, Equatable {
    let challenge: String
    let relyingPartyID: String
    let userID: String?
}

struct PasskeyFinishRequest: Codable, Equatable {
    let challenge: String
    let credentialID: String
    let userHandle: String?
    let deviceID: String?
    let deviceName: String?
    let platform: String?
    let transports: String?
    let clientDataJSON: String?
    let authenticatorData: String?
    let signature: String?
}
