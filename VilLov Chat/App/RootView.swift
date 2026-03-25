//
//  RootView.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//

import SwiftUI

enum AppState {
    case unauthenticated
    case authenticated
}

struct RootView: View {
    @State private var appState: AppState = .unauthenticated

    var body: some View {
        switch appState {
        case .unauthenticated:
            Text("Welcome Screen") // replace with WelcomeScreen()
        case .authenticated:
            Text("Main App") // replace with ConversationListScreen()
        }
    }
}
