import XCTest
@testable import Leaderboard

final class LeaderboardTests: XCTestCase {
    func testResignedGroupSelection() {
        let base = AppGroup.baseIdentifier
        XCTAssertEqual(AppGroup.resolvedIdentifier(in: [base]), base)
        XCTAssertEqual(AppGroup.resolvedIdentifier(in: ["group.unrelated", base + ".TEAM123"]), base + ".TEAM123")
        XCTAssertNil(AppGroup.resolvedIdentifier(in: [base + "Other.TEAM123"]))
        XCTAssertNil(AppGroup.resolvedIdentifier(in: [base + ".TEAM1", base + ".TEAM2"]))
    }

    func testProvisioningProfileGroupExtraction() throws {
        let groups = [AppGroup.baseIdentifier + ".TEAM123"]
        let plist = try PropertyListSerialization.data(fromPropertyList: [
            "Entitlements": ["com.apple.security.application-groups": groups]
        ], format: .xml, options: 0)
        let envelope = Data([0x30, 0x82, 0xff]) + plist + Data([0, 1, 2])
        XCTAssertEqual(AppGroup.groups(in: envelope), groups)
        XCTAssertNil(AppGroup.groups(in: Data("invalid profile".utf8)))
        XCTAssertNil(AppGroup.groups(in: Data("<?xml incomplete".utf8)))
    }

    func testShareTextUsesCurrentRanking() {
        let list = RankedList(title: "Desserts")
        list.items = [
            RankedItem(text: "Pie", rank: 1),
            RankedItem(text: "Cake", rank: 0)
        ]

        XCTAssertEqual(list.shareText, "Desserts\n1. Cake\n2. Pie")
    }
}
