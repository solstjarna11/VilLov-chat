import Foundation

extension Contact {
    static let mockData: [Contact] = [
        Contact(id: UUID(), name: "Alice Johnson", isVerified: true),
        Contact(id: UUID(), name: "Bob Smith", isVerified: false),
        Contact(id: UUID(), name: "Charlie Team", isVerified: true)
    ]
}