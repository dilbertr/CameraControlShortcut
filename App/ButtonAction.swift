import Foundation

/// Something Camera Control can do when pressed.
struct ButtonAction: Identifiable, Codable, Equatable {
    enum Kind: String, Codable, CaseIterable, Identifiable {
        case openApp, shortcut, url
        /// Does nothing itself: a Shortcuts automation triggered by "CamControl is
        /// opened" does the work in the background, then CamControl gets out of the way.
        case automation

        var id: String { rawValue }

        var title: String {
            switch self {
            case .openApp: return "Open App"
            case .shortcut: return "Run Shortcut"
            case .url: return "Open URL"
            case .automation: return "Shortcuts Automation"
            }
        }

        /// Short enough for the editor's segmented picker.
        var shortTitle: String {
            switch self {
            case .openApp: return "App"
            case .shortcut: return "Shortcut"
            case .url: return "URL"
            case .automation: return "Automation"
            }
        }

        var symbol: String {
            switch self {
            case .openApp: return "square.grid.2x2.fill"
            case .shortcut: return "square.2.layers.3d.top.filled"
            case .url: return "link"
            case .automation: return "gearshape.2.fill"
            }
        }
    }

    var id = UUID()
    var name: String
    var kind: Kind
    /// Open App: the app's URL (e.g. `spotify://`). Shortcut: the shortcut's name. URL: the URL.
    var value: String = ""
    /// Shortcut only: optional text passed as the shortcut's input.
    var shortcutInput: String = ""

    var subtitle: String {
        switch kind {
        case .openApp: return AppCatalog.app(forURL: value)?.name ?? value
        case .shortcut: return "Shortcut: \(value)"
        case .url: return value
        case .automation: return "Runs in the background via a Shortcuts automation"
        }
    }

    /// Whether the action has everything it needs to run.
    var isRunnable: Bool {
        kind == .automation || launchURL != nil
    }

    /// The URL to hand to `UIApplication.open`, or nil for an automation.
    var launchURL: URL? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        switch kind {
        case .automation:
            return nil
        case .openApp:
            return Self.normalizedSchemeURL(trimmed)
        case .url:
            return Self.normalizedWebURL(trimmed)
        case .shortcut:
            guard !trimmed.isEmpty else { return nil }
            var components = URLComponents()
            components.scheme = "shortcuts"
            components.host = "run-shortcut"
            var items = [URLQueryItem(name: "name", value: trimmed)]
            let input = shortcutInput.trimmingCharacters(in: .whitespacesAndNewlines)
            if !input.isEmpty {
                items += [URLQueryItem(name: "input", value: "text"), URLQueryItem(name: "text", value: input)]
            }
            components.queryItems = items
            return components.url
        }
    }

    /// Accepts `spotify`, `spotify:` or `spotify://…`.
    private static func normalizedSchemeURL(_ text: String) -> URL? {
        guard !text.isEmpty else { return nil }
        if text.contains(":") { return URL(string: text) }
        return URL(string: text + "://")
    }

    /// Accepts `example.com` (becomes https://example.com) or any URL with a scheme.
    private static func normalizedWebURL(_ text: String) -> URL? {
        guard !text.isEmpty, !text.contains(" ") else { return nil }
        if let url = URL(string: text), url.scheme != nil { return url }
        return URL(string: "https://" + text)
    }
}
