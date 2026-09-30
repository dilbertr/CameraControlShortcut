import Foundation

/// The user's saved actions and which one Camera Control runs. Persisted in UserDefaults.
@MainActor
final class ActionStore: ObservableObject {
    @Published var actions: [ButtonAction] { didSet { save() } }
    @Published var activeID: UUID? { didSet { save() } }

    private let defaults: UserDefaults
    private static let actionsKey = "actions"
    private static let activeKey = "activeActionID"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        // Decode entries one by one so ones from older versions (like the removed
        // built-in Camera action) are skipped instead of discarding the whole list.
        let loaded = defaults.data(forKey: Self.actionsKey)
            .flatMap { try? JSONDecoder().decode([Lenient].self, from: $0) }?
            .compactMap(\.action) ?? []
        actions = loaded
        let savedActive = defaults.string(forKey: Self.activeKey).flatMap(UUID.init(uuidString:))
        activeID = loaded.contains { $0.id == savedActive } ? savedActive : loaded.first?.id
    }

    var activeAction: ButtonAction? {
        actions.first { $0.id == activeID }
    }

    func upsert(_ action: ButtonAction) {
        if let index = actions.firstIndex(where: { $0.id == action.id }) {
            actions[index] = action
        } else {
            actions.append(action)
        }
    }

    func delete(_ action: ButtonAction) {
        actions.removeAll { $0.id == action.id }
        if activeID == action.id { activeID = actions.first?.id }
    }

    func move(from source: IndexSet, to destination: Int) {
        actions.move(fromOffsets: source, toOffset: destination)
    }

    private func save() {
        if let data = try? JSONEncoder().encode(actions) {
            defaults.set(data, forKey: Self.actionsKey)
        }
        defaults.set(activeID?.uuidString, forKey: Self.activeKey)
    }

    private struct Lenient: Decodable {
        let action: ButtonAction?
        init(from decoder: Decoder) throws {
            action = try? ButtonAction(from: decoder)
        }
    }
}
