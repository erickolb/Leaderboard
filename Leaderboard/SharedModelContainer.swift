import Foundation
import SwiftData

enum AppGroup {
    // Change this in both entitlements files if you change the app's bundle ID.
    static let baseIdentifier = "group.me.erickolb.Leaderboard"

    // SideStore may append the signing team's ID. Read each bundle's installed
    // profile so the app and share extension resolve the same shared container.
    static var identifier: String {
        guard let url = Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision"),
              let data = try? Data(contentsOf: url),
              let groups = groups(in: data) else { return baseIdentifier }
        return resolvedIdentifier(in: groups) ?? baseIdentifier
    }

    static func resolvedIdentifier(in groups: [String]) -> String? {
        if groups.contains(baseIdentifier) { return baseIdentifier }
        let matches = Set(groups.filter { $0.hasPrefix(baseIdentifier + ".") })
        return matches.count == 1 ? matches.first : nil
    }

    static func groups(in profile: Data) -> [String]? {
        // Extract metadata from the CMS envelope; iOS validates its signature.
        guard let start = profile.range(of: Data("<?xml".utf8)),
              let end = profile.range(of: Data("</plist>".utf8),
                                      in: start.lowerBound..<profile.endIndex),
              let plist = try? PropertyListSerialization.propertyList(
                from: profile.subdata(in: start.lowerBound..<end.upperBound),
                options: [], format: nil) as? [String: Any],
              let entitlements = plist["Entitlements"] as? [String: Any] else { return nil }
        return entitlements["com.apple.security.application-groups"] as? [String]
    }
}

enum SharedModelContainer {
    static func make() -> ModelContainer {
        let schema = Schema([RankedList.self, RankedItem.self])
        let group = AppGroup.identifier
        #if !targetEnvironment(simulator)
        guard FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group) != nil else {
            fatalError("Shared storage is unavailable for \(group). Reinstall with the share extension and App Group enabled.")
        }
        #endif
        let configuration = ModelConfiguration(
            "Leaderboard",
            schema: schema,
            groupContainer: .identifier(group)
        )

        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("Unable to open the shared Leaderboard database: \(error)")
        }
    }
}
