//
//  AppProviders.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//


import Foundation

enum AppProviders {
    static let mock = MockDataProvider()

    static var conversations: ConversationProviding { mock }
    static var contacts: ContactProviding { mock }
    static var devices: DeviceProviding { mock }
    static var messages: MessageProviding { mock }
}