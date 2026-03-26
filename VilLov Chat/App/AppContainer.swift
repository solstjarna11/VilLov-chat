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

    let tokenStore: AuthTokenStore
    let apiClient: APIClient

    let authService: AuthService
    let keyDirectoryService: KeyDirectoryService
    let relayService: RelayService
    let conversationService: ConversationService

    init() {
        let providers = AppProviders.mock

        let tokenStore = AuthTokenStore()
        let apiClient = APIClient(
            baseURL: URL(string: "http://127.0.0.1:8000")!,
            tokenStore: tokenStore
        )

        let authenticator = StubPasskeyAuthenticator()

        let authService = AuthService(
            apiClient: apiClient,
            tokenStore: tokenStore,
            authenticator: authenticator
        )

        let keyDirectoryService = KeyDirectoryService(apiClient: apiClient)
        let relayService = RelayService(apiClient: apiClient)
        let conversationService = ConversationService(
            apiClient: apiClient,
            keyDirectoryService: keyDirectoryService,
            relayService: relayService,
            e2eeEngine: StubE2EEEngine()
        )

        let session = AppSession(tokenStore: tokenStore)

        self.tokenStore = tokenStore
        self.apiClient = apiClient
        self.authService = authService
        self.keyDirectoryService = keyDirectoryService
        self.relayService = relayService
        self.conversationService = conversationService
        self.session = session

        self.environment = AppEnvironment(
            session: session,
            providers: providers,
            authService: authService,
            conversationService: conversationService,
            keyDirectoryService: keyDirectoryService,
            relayService: relayService
        )
    }
}
