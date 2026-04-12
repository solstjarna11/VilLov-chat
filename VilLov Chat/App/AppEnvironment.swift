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

    let authService: AuthService
    let conversationService: ConversationServicing
    let contactService: ContactService
    let conversationDirectoryService: ConversationDirectoryService
    let keyDirectoryService: KeyDirectoryService
    let relayService: RelayService

    init(
        session: AppSession,
        providers: AppProviders,
        authService: AuthService,
        conversationService: ConversationServicing,
        contactService: ContactService,
        conversationDirectoryService: ConversationDirectoryService,
        keyDirectoryService: KeyDirectoryService,
        relayService: RelayService
    ) {
        self.session = session
        self.providers = providers
        self.authService = authService
        self.conversationService = conversationService
        self.contactService = contactService
        self.conversationDirectoryService = conversationDirectoryService
        self.keyDirectoryService = keyDirectoryService
        self.relayService = relayService
    }
}
