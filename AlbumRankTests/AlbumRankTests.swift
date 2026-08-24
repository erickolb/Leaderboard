import XCTest
@testable import AlbumRank

final class AlbumRankTests: XCTestCase {
    func testShareTextUsesCurrentRanking() {
        let list = RankedList(title: "Desserts")
        list.items = [
            RankedItem(text: "Pie", rank: 1),
            RankedItem(text: "Cake", rank: 0)
        ]

        XCTAssertEqual(list.shareText, "Desserts\n1. Cake\n2. Pie")
    }
}
