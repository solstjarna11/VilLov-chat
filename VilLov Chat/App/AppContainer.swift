//
//  AppContainer.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 26.3.2026.
//
// This is the composition root. Right now it only owns app-wide objects. Later it will own services, network, crypto, and live repositories.


import Foundation

@MainActor
final class AppContainer {
    let session: AppSession
    let environment: AppEnvironment

    init() {
        let session = AppSession()
        let providers = AppProviders.mock

        self.session = session
        self.environment = AppEnvironment(
            session: session,
            providers: providers
        )
    }
}
