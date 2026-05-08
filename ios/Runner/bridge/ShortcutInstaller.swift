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

        var components = URLComponents(string: "shortcuts://import-workflow")!
        components.queryItems = [
            URLQueryItem(name: "url",  value: hosted),
            URLQueryItem(name: "name", value: "LogTransaction")
        ]
        // URLComponents.url is non-nil when the base URL is valid and query
        // items don't contain characters that can't be percent-encoded.
        return components.url ?? URL(string: "shortcuts://")!
    }
}
