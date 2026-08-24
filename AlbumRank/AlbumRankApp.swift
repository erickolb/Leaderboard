import SwiftUI
import SwiftData

@main
struct AlbumRankApp: App {
    var body: some Scene {
        WindowGroup {
            ListsView()
        }
        .modelContainer(SharedModelContainer.make())
    }
}
