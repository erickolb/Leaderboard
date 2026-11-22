import Foundation

enum AlbumTextParser {
    static func bestAlbumText(from candidates: [String]) -> String {
        if let complete = completeMusicText(from: candidates) { return complete }
        return candidates.map { cleanedTitle(cleaned($0)) }
            .first(where: { !$0.isEmpty && !looksLikeURL($0) }) ?? ""
    }

    // Search all candidates before falling back to a title without an artist.
    // Amazon's supplied text is more informative than a title-only link preview.
    static func completeMusicText(from candidates: [String]) -> String? {
        let values = candidates.map(withoutURLs)
        for value in values {
            if let result = quotedMusicText(value, pattern:
                #"^(?:Check out\s+)?["“](.+)["”]\s+by\s+(.+?)\s+on\s+Amazon Music(?: Unlimited)?[.!]?$"#) {
                return result
            }
        }
        for rawValue in values {
            let value = cleaned(rawValue)
            guard !value.isEmpty, !looksLikeURL(value) else { continue }
            if let result = quotedMusicText(value, pattern: #"^(?:Check out\s+)?["“](.+)["”]\s+by\s+(.+)$"#) {
                return result
            }

            if let separator = value.range(of: " by ", options: .caseInsensitive) {
                let album = cleanedTitle(String(value[..<separator.lowerBound])
                    .trimmingCharacters(in: CharacterSet(charactersIn: "\"“”")))
                let artist = cleaned(String(value[separator.upperBound...]))
                if !album.isEmpty, !artist.isEmpty { return "\(artist) - \(album)" }
            }

            if let separator = value.range(of: #"\s+[-–—]\s+"#, options: .regularExpression) {
                let album = cleanedTitle(String(value[..<separator.lowerBound]))
                let artist = cleaned(String(value[separator.upperBound...]))
                if !album.isEmpty, !artist.isEmpty { return "\(artist) - \(album)" }
            }

        }
        return nil
    }

    private static func quotedMusicText(_ value: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: value, range: NSRange(value.startIndex..., in: value)),
              let titleRange = Range(match.range(at: 1), in: value),
              let artistRange = Range(match.range(at: 2), in: value) else { return nil }
        let title = cleanedTitle(String(value[titleRange]))
        let artist = cleaned(String(value[artistRange]))
        guard !title.isEmpty, !artist.isEmpty else { return nil }
        return "\(artist) - \(title)"
    }

    private static func cleanedTitle(_ value: String) -> String {
        cleaned(value.replacingOccurrences(
            of: #"\s*\[Explicit\]\s*"#,
            with: " ",
            options: [.regularExpression, .caseInsensitive]
        ))
    }

    private static func cleaned(_ value: String) -> String {
        withoutURLs(value)
            .replacingOccurrences(of: #"\s*(?:\||on)\s+Amazon Music(?: Unlimited)?[.!]?\s*$"#,
                                  with: "", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func withoutURLs(_ value: String) -> String {
        value.replacingOccurrences(of: #"https?://\S+"#, with: "", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func looksLikeURL(_ value: String) -> Bool {
        value.lowercased().hasPrefix("http://") || value.lowercased().hasPrefix("https://")
    }
}
