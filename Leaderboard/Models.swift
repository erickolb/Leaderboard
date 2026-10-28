import Foundation
import SwiftData

@Model
final class RankedList {
    var id: UUID = UUID()
    var title: String
    var createdAt: Date
    var sortOrder: Int = 0

    @Relationship(deleteRule: .cascade, inverse: \RankedItem.list)
    var items: [RankedItem]

    init(title: String, createdAt: Date = .now, items: [RankedItem] = [], sortOrder: Int = 0) {
        self.title = title
        self.createdAt = createdAt
        self.items = items
        self.sortOrder = sortOrder
    }

    var rankedItems: [RankedItem] {
        items.sorted {
            if $0.rank == $1.rank { return $0.createdAt < $1.createdAt }
            return $0.rank < $1.rank
        }
    }

    var shareText: String {
        let heading = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let rows = rankedItems.enumerated().map { index, item in
            "\(index + 1). \(item.text)"
        }
        return ([heading] + rows).joined(separator: "\n")
    }
}

@Model
final class RankedItem {
    var id: UUID = UUID()
    var text: String
    var rank: Int
    var createdAt: Date
    var list: RankedList?

    init(text: String, rank: Int, createdAt: Date = .now, list: RankedList? = nil) {
        self.text = text
        self.rank = rank
        self.createdAt = createdAt
        self.list = list
    }
}
