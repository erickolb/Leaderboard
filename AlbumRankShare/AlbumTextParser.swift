import Foundation

enum AlbumTextParser {
    static func bestAlbumText(from candidates: [String]) -> String {
        for rawValue in candidates {
            let value = cleaned(rawValue)
            guard !value.isEmpty, !looksLikeURL(value) else { continue }

            if let separator = value.range(of: " by ", options: .caseInsensitive) {
                let album = cleaned(String(value[..<separator.lowerBound]))
                    .trimmingCharacters(in: CharacterSet(charactersIn: "\"“”"))
                let artist = cleaned(String(value[separator.upperBound...]))
                if !album.isEmpty, !artist.isEmpty { return "\(artist) - \(album)" }
            }

            if let separator = value.range(of: " - ") {
                let album = cleaned(String(value[..<separator.lowerBound]))
                let artist = cleaned(String(value[separator.upperBound...]))
                if !album.isEmpty, !artist.isEmpty { return "\(artist) - \(album)" }
            }

            return value
        }
        return ""
    }

    private static func cleaned(_ value: String) -> String {
        value
            .replacingOccurrences(of: #"\s*(?:\||on)\s+Amazon Music(?: Unlimited)?\s*$"#,
                                  with: "", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func looksLikeURL(_ value: String) -> Bool {
        value.lowercased().hasPrefix("http://") || value.lowercased().hasPrefix("https://")
    }
}
