//
//  AppContainer.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 26.3.2026.
//

import Foundation

@MainActor
final class AppContainer {
    let session: AppSession
    let environment: AppEnvironment

    let tokenStore: AuthTokenStore
    let apiClient: APIClient

    let authService: AuthService
    let contactService: ContactService
    let conversationDirectoryService: ConversationDirectoryService
    let keyDirectoryService: KeyDirectoryService
    let relayService: RelayService
    let conversationService: ConversationService

    init() {
        let providers = AppProviders(
            conversations: EmptyConversationProvider(),
            contacts: EmptyContactProvider(),
            devices: EmptyDeviceProvider(),
            messages: EmptyMessageProvider()
        )

        let tokenStore = AuthTokenStore()
        let apiClient = APIClient(
            baseURL: URL(string: "https://auth.villovchat.com")!,
            tokenStore: tokenStore
        )

        let authenticator = DevelopmentPasskeyAuthenticator(
            credentialStore: DevPasskeyCredentialStore()
        )

        let authService = AuthService(
            apiClient: apiClient,
            tokenStore: tokenStore,
            authenticator: authenticator
        )

        let contactService = ContactService(apiClient: apiClient)
        let conversationDirectoryService = ConversationDirectoryService(apiClient: apiClient)
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
        self.contactService = contactService
        self.conversationDirectoryService = conversationDirectoryService
        self.keyDirectoryService = keyDirectoryService
        self.relayService = relayService
        self.conversationService = conversationService
        self.session = session

        self.environment = AppEnvironment(
            session: session,
            providers: providers,
            authService: authService,
            conversationService: conversationService,
            contactService: contactService,
            conversationDirectoryService: conversationDirectoryService,
            keyDirectoryService: keyDirectoryService,
            relayService: relayService
        )
    }
}
