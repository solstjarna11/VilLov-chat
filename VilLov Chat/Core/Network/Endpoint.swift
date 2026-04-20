//
//  Endpoint.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 26.3.2026.
//
// This keeps routes in one place


import Foundation

enum Endpoint {
    case passkeyRegisterBegin
    case passkeyRegisterFinish
    case passkeyLoginBegin
    case passkeyLoginFinish

    case passkeyBegin
    case passkeyFinish

    case contacts
    case conversations
    case getOrCreateConversation

    case keyBundle(userID: String)
    case uploadKeys
    case sendMessage
    case inbox
    case ackMessage
    case myOPKCount

    var path: String {
        switch self {
        case .passkeyRegisterBegin:
            return "/auth/passkey/register/begin"
        case .passkeyRegisterFinish:
            return "/auth/passkey/register/finish"
        case .passkeyLoginBegin:
            return "/auth/passkey/login/begin"
        case .passkeyLoginFinish:
            return "/auth/passkey/login/finish"

        case .passkeyBegin:
            return "/auth/passkey/begin"
        case .passkeyFinish:
            return "/auth/passkey/finish"

        case .contacts:
            return "/contacts"
        case .conversations:
            return "/conversations"
        case .getOrCreateConversation:
            return "/conversations/get-or-create"

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
        case .myOPKCount:
            return "/keys/me/opk-count"
        }
    }
}
