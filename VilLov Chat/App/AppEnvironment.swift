//
//  AppEnvironment.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//


import Foundation

enum AppEnvironment {
    static let isDevelopmentAuthBypassEnabled = true

    static let initialAppState: AppState = .authenticated
    // static let initialAppState: AppState = .unauthenticated // for unauthenticated testing
}
