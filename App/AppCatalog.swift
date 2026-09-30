import Foundation

/// iOS can only open other apps through URL schemes, so "Open App" picks from
/// apps with known schemes. Anything else: use a custom scheme, or make a
/// Shortcut with an "Open App" step and use "Run Shortcut".
enum AppCatalog {
    struct App: Identifiable, Hashable {
        let name: String
        let url: String
        let symbol: String
        var id: String { url }
    }

    static let apple: [App] = [
        App(name: "App Store", url: "itms-apps://", symbol: "bag.fill"),
        App(name: "Calendar", url: "calshow://", symbol: "calendar"),
        App(name: "Files", url: "shareddocuments://", symbol: "folder.fill"),
        App(name: "Mail", url: "message://", symbol: "envelope.fill"),
        App(name: "Maps", url: "maps://", symbol: "map.fill"),
        App(name: "Messages", url: "sms:", symbol: "message.fill"),
        App(name: "Music", url: "music://", symbol: "music.note"),
        App(name: "Notes", url: "mobilenotes://", symbol: "note.text"),
        App(name: "Photos", url: "photos-redirect://", symbol: "photo.on.rectangle"),
        App(name: "Podcasts", url: "podcasts://", symbol: "mic.fill"),
        App(name: "Reminders", url: "x-apple-reminderkit://", symbol: "checklist"),
        App(name: "Settings", url: "App-prefs:", symbol: "gearshape.fill"),
        App(name: "Shortcuts", url: "shortcuts://", symbol: "square.2.layers.3d.top.filled"),
        App(name: "Wallet", url: "shoebox://", symbol: "wallet.pass.fill"),
        App(name: "Weather", url: "weather://", symbol: "cloud.sun.fill"),
    ]

    static let thirdParty: [App] = [
        App(name: "Gmail", url: "googlegmail://", symbol: "envelope"),
        App(name: "Google Maps", url: "comgooglemaps://", symbol: "map"),
        App(name: "Instagram", url: "instagram://", symbol: "camera.aperture"),
        App(name: "Notion", url: "notion://", symbol: "doc.text"),
        App(name: "Obsidian", url: "obsidian://", symbol: "diamond"),
        App(name: "Slack", url: "slack://", symbol: "number"),
        App(name: "Spotify", url: "spotify://", symbol: "music.note.list"),
        App(name: "Telegram", url: "tg://", symbol: "paperplane.fill"),
        App(name: "WhatsApp", url: "whatsapp://", symbol: "phone.bubble.fill"),
        App(name: "X", url: "twitter://", symbol: "xmark"),
        App(name: "YouTube", url: "youtube://", symbol: "play.rectangle.fill"),
    ]

    static func app(forURL url: String) -> App? {
        (apple + thirdParty).first { $0.url == url }
    }
}
