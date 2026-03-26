//
//  Endpoint.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 26.3.2026.
//
// This keeps routes in one place


import Foundation

enum Endpoint {
    case passkeyBegin
    case passkeyFinish
    case keyBundle(userID: String)
    case uploadKeys
    case sendMessage
    case inbox
    case ackMessage

    var path: String {
        switch self {
        case .passkeyBegin:
            return "/auth/passkey/begin"
        case .passkeyFinish:
            return "/auth/passkey/finish"
        case .keyBundle(let userID):
            return "/keys/\(userID)/bundle"
        case .uploadKeys:
            return "/keys/upload"
        case .sendMessage:
            return "/messages/send"
        case .inbox:
            return "/messages/inbox"
        case .ackMessage:
            return "/messages/ack"
        }
    }
}
