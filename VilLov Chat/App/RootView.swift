//
//  RootView.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//

import SwiftUI

struct RootView: View {
    @State private var appState: AppState = .launching

    var body: some View {
        Group {
            switch appState {
            case .launching:
                LaunchScreen()
            case .unauthenticated:
                WelcomeScreen()
            case .authenticated:
                MainTabView()
            }
        }
        .task {
            await determineInitialAppState()
        }
    }

    private func determineInitialAppState() async {
        // Real implementation path:
        // - check whether local app bootstrap data exists
        // - check whether user has an authenticated session
        // - later check device registration / passkey state
        //
        // For now, keep the state decision centralized here.
        appState = .unauthenticated
    }
}
