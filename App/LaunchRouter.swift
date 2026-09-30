import Foundation

/// Bridges `CaptureIntent.perform()` (which runs when Camera Control launches the
/// unlocked app) to the UI, which runs the active action once the scene is active.
@MainActor
final class LaunchRouter: ObservableObject {
    static let shared = LaunchRouter()

    /// Set when Camera Control was pressed and the action hasn't run yet.
    @Published private(set) var pendingPress: UUID?

    func cameraControlPressed() {
        pendingPress = UUID()
    }

    /// Returns true once per press.
    func consumePress() -> Bool {
        guard pendingPress != nil else { return false }
        pendingPress = nil
        return true
    }
}
