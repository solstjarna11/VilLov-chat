//
//  AppProviders.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//


import Foundation

struct AppProviders {
    let conversations: ConversationProviding
    let contacts: ContactProviding
    let devices: DeviceProviding
    let messages: MessageProviding

    init(
        conversations: ConversationProviding,
        contacts: ContactProviding,
        devices: DeviceProviding,
        messages: MessageProviding
    ) {
        self.conversations = conversations
        self.contacts = contacts
        self.devices = devices
        self.messages = messages
    }
}

extension AppProviders {
    static let mock: AppProviders = {
        let mock = MockDataProvider()

        return AppProviders(
            conversations: mock,
            contacts: mock,
            devices: mock,
            messages: mock
        )
    }()
}
