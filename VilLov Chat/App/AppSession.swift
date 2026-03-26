//
//  AppSession.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 26.3.2026.
//


import Foundation
import Observation

@MainActor
@Observable
final class AppSession {
    var state: AppState = .launching
    var currentUserID: String?
    var isPasskeyConfigured: Bool = false

    private let tokenStore: AuthTokenStore

    init(tokenStore: AuthTokenStore) {
        self.tokenStore = tokenStore
    }

    func finishLaunch() {
        state = tokenStore.isAuthenticated ? .authenticated : .unauthenticated
    }

    func completeAuthentication(
        userID: String? = nil,
        isPasskeyConfigured: Bool = true
    ) {
        self.currentUserID = userID
        self.isPasskeyConfigured = isPasskeyConfigured
        self.state = .authenticated
    }

    func signOut() {
        tokenStore.clear()
        currentUserID = nil
        isPasskeyConfigured = false
        state = .unauthenticated
    }
}
