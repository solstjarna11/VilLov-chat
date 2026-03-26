//
//  DevAuthAccount.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 26.3.2026.
//


import Foundation

enum DevAuthAccount: String, CaseIterable, Identifiable {
    case alice = "user_alice"
    case bob = "user_bob"
    case charlie = "user_charlie"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .alice:
            return "Alice"
        case .bob:
            return "Bob"
        case .charlie:
            return "Charlie"
        }
    }

    var userHandle: String {
        rawValue
    }
}