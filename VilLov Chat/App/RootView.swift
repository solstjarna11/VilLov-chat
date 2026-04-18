//
//  RootView.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//

import SwiftUI

struct RootView: View {
    let environment: AppEnvironment

    var body: some View {
        @Bindable var session = environment.session

        Group {
            switch session.state {
            case .launching:
                LaunchScreen()
                    .task {
                        session.finishLaunch()
                    }

            case .unauthenticated:
                WelcomeScreen(environment: environment)

            case .authenticated:
                if let currentUserID = session.currentUserID {
                    MainTabView(
                        environment: environment,
                        currentUserID: currentUserID
                    )
                } else {
                    WelcomeScreen(environment: environment)
                        .task {
                            session.signOut()
                        }
                }
            }
        }
    }
}
