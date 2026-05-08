import Foundation

/// Builds the URL that opens Shortcuts and offers to install our pre-built
/// LogTransaction shortcut with a single tap.
///
/// The hosted `.shortcut` file URL is read from Info.plist key
/// `ShortcutInstallURL`. If the key is absent (e.g. in development), the URL
/// falls back to `shortcuts://` which simply opens the Shortcuts app.
enum ShortcutInstaller {

    static var installURL: URL {
        let hosted = Bundle.main.object(forInfoDictionaryKey: "ShortcutInstallURL") as? String

        guard let hosted, !hosted.isEmpty else {
            return URL(string: "shortcuts://")!
        }

        // If it's an iCloud link, open it directly so iOS shows the "Add Shortcut" UI.
        if hosted.contains("icloud.com/shortcuts") {
            return URL(string: hosted)!
        }

        var components = URLComponents(string: "shortcuts://import-workflow")!
        components.queryItems = [
            URLQueryItem(name: "url",  value: hosted),
            URLQueryItem(name: "name", value: "LogTransaction")
        ]
        return components.url ?? URL(string: "shortcuts://")!
    }
}
