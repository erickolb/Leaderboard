import SwiftUI
import SwiftData

@main
struct LeaderboardApp: App {
    var body: some Scene {
        WindowGroup {
            ListsView()
        }
        .modelContainer(SharedModelContainer.make())
    }
}
