import Foundation
import SwiftData

enum AppGroup {
    // Change this in both entitlements files if you change the app's bundle ID.
    static let identifier = "group.me.erickolb.AlbumRank"
}

enum SharedModelContainer {
    static func make() -> ModelContainer {
        let schema = Schema([RankedList.self, RankedItem.self])
        let configuration = ModelConfiguration(
            "AlbumRank",
            schema: schema,
            groupContainer: .identifier(AppGroup.identifier)
        )

        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("Unable to open the shared AlbumRank database: \(error)")
        }
    }
}
