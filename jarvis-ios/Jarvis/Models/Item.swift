import Foundation
import SwiftData

@Model
final class Item {
    var title: String
    var itemDescription: String?
    var timestamp: Date

    init(title: String, itemDescription: String? = nil, timestamp: Date = Date()) {
        self.title = title
        self.itemDescription = itemDescription
        self.timestamp = timestamp
    }
}
