//
//  AppSession.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 26.3.2026.
//


import Foundation
import Observation

@Observable
final class AppSession {
    var state: AppState = .launching
    var currentUserID: String?
    var isPasskeyConfigured: Bool = false

    func finishLaunch() {
        // For now, default into the unauthenticated flow.
        // Later, this is where token restore / session restore will happen.
        state = .unauthenticated
    }

    func signIn(userID: String? = nil, isPasskeyConfigured: Bool = true) {
        self.currentUserID = userID
        self.isPasskeyConfigured = isPasskeyConfigured
        self.state = .authenticated
    }

    func signOut() {
        currentUserID = nil
        isPasskeyConfigured = false
        state = .unauthenticated
    }
}