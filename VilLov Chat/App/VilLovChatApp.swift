//
//  VilLovChatApp.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//

import SwiftUI

@main
struct VilLovChatApp: App {
    @State private var container = AppContainer()

    var body: some Scene {
        WindowGroup {
            RootView(environment: container.environment)
        }
    }
}
