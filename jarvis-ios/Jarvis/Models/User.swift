import Foundation

struct User: Identifiable, Codable {
    let id: UUID
    var name: String
    var email: String
    var bio: String
    var memberSince: Date

    init(id: UUID = UUID(), name: String, email: String, bio: String, memberSince: Date) {
        self.id = id
        self.name = name
        self.email = email
        self.bio = bio
        self.memberSince = memberSince
    }
}

struct UserStats {
    var totalItems: Int
    var itemsThisWeek: Int
    var itemsThisMonth: Int
}

struct Activity: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    let timestamp: Date
}

import SwiftUI

struct License: Identifiable {
    let id = UUID()
    let name: String
    let type: String
}
