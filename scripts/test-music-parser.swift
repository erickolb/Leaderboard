import Foundation

@main
struct MusicParserTests {
    static func main() {
        let muse = "Check out \"Nightshift Superstar\" by Muse on Amazon Music."
        let beck = "Check out \"Ride Lonesome\" by Beck on Amazon Music.https://music.amazon.com/albums/B0H87FCVJ4?do=play&trackAsin=B0H87PGMRF"
        let cases: [(String, [String], String)] = [
            ("Captured Muse track", [muse], "Muse - Nightshift Superstar"),
            ("Complete share beats title-only preview", ["Nightshift Superstar", muse], "Muse - Nightshift Superstar"),
            ("Amazon text beats generic metadata", ["Other Title by Other Artist", muse], "Muse - Nightshift Superstar"),
            ("Copied track with attached URL", [beck], "Beck - Ride Lonesome"),
            ("Separate URL attachment", ["https://music.amazon.com/albums/ABC?trackAsin=XYZ", muse], "Muse - Nightshift Superstar"),
            ("Existing album metadata", ["Absolution by Muse on Amazon Music"], "Muse - Absolution"),
            ("Existing dash-separated album", ["Absolution — Muse | Amazon Music"], "Muse - Absolution"),
            ("Explicit label", ["Check out \"Absolution [Explicit]\" by Muse on Amazon Music."], "Muse - Absolution"),
            ("Curly quotes and title containing by", ["Check out “Stand by Me” by Ben E. King on Amazon Music."], "Ben E. King - Stand by Me"),
            ("Artist containing by", ["Check out \"Stand by Me\" by Guided by Voices on Amazon Music."], "Guided by Voices - Stand by Me"),
            ("Quoted title inside quoted envelope", ["Check out \"A \"Quoted\" Track\" by Artist on Amazon Music."], "Artist - A \"Quoted\" Track"),
            ("Whitespace and Unicode", [" Check out  \"Déjà Vu\"\n by Beyoncé on Amazon Music. "], "Beyoncé - Déjà Vu"),
            ("Title-only fallback stays editable", ["Absolution", "https://music.amazon.com/albums/ABC"], "Absolution"),
            ("Empty and URL-only input", ["", "https://music.amazon.com/albums/ABC"], ""),
            ("Later album with artist beats earlier title", ["Absolution", "Absolution by Muse"], "Muse - Absolution"),
            ("Quoted metadata without branding", ["\"Absolution\" by Muse"], "Muse - Absolution"),
            ("Unlimited branding", ["Absolution by Muse on Amazon Music Unlimited."], "Muse - Absolution"),
            ("Explicit title fallback", ["Absolution [Explicit]"], "Absolution")
        ]
        var failures = 0
        for (name, input, expected) in cases {
            let actual = AlbumTextParser.bestAlbumText(from: input)
            if actual != expected {
                print("FAIL: \(name): expected \(expected.debugDescription), got \(actual.debugDescription)")
                failures += 1
            }
        }
        if AlbumTextParser.completeMusicText(from: ["Nightshift Superstar"]) != nil {
            print("FAIL: title alone must remain eligible for metadata lookup")
            failures += 1
        }
        if AlbumTextParser.completeMusicText(from: [muse]) != "Muse - Nightshift Superstar" {
            print("FAIL: captured text must be sufficient without a network lookup")
            failures += 1
        }
        guard failures == 0 else { exit(1) }
        print("20 music parser checks passed (track shares, album regressions, and metadata fallback).")
    }
}
