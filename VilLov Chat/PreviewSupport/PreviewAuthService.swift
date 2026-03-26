//
//  PreviewAuthService.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 26.3.2026.
//


import Foundation

enum PreviewAuthService {
    @MainActor
    static func make() -> AuthService {
        let tokenStore = AuthTokenStore()
        let apiClient = APIClient(
            baseURL: URL(string: "http://127.0.0.1:8000")!,
            tokenStore: tokenStore
        )

        return AuthService(
            apiClient: apiClient,
            tokenStore: tokenStore,
            authenticator: StubPasskeyAuthenticator()
        )
    }
}
