//
//  AuthTokenStore.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 26.3.2026.
//
// For now this is in-memory. Later we can move it to Keychain.

import Foundation
import Observation

@MainActor
@Observable
final class AuthTokenStore {
    private(set) var sessionToken: SessionToken?

    var accessToken: String? {
        sessionToken?.accessToken
    }

    var isAuthenticated: Bool {
        sessionToken != nil
    }

    func setSessionToken(_ token: SessionToken) {
        sessionToken = token
    }

    func clear() {
        sessionToken = nil
    }
}
