//
//  AppEnvironment.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//


import Foundation

struct AppEnvironment {
    let session: AppSession
    let providers: AppProviders

    init(
        session: AppSession,
        providers: AppProviders
    ) {
        self.session = session
        self.providers = providers
    }
}
