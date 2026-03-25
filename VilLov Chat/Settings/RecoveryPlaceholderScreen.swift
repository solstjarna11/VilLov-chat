import SwiftUI

struct RecoveryPlaceholderScreen: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "key")
                .font(.system(size: 48))

            Text("Recovery Options")
                .font(.title2)
                .fontWeight(.semibold)

            Text("This screen will later handle account recovery, trusted recovery methods, and secure re-access flows.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .navigationTitle("Recovery Options")
    }
}