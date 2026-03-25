//
//  LaunchScreen.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//

import SwiftUI

struct LaunchScreen: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.background)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("VilLov Chat")
                    .font(.largeTitle)
                    .fontWeight(.semibold)

                ProgressView()
            }
        }
    }
}
