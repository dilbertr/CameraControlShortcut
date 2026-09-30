import AppIntents

/// The intent the system runs when Camera Control is pressed.
///
/// This file must be compiled into both the app and the capture extension,
/// otherwise the system won't offer the app as a Camera Control option.
///
/// - Unlocked: the system launches the app and calls `perform()` there.
/// - Lock Screen: the system launches `CaptureExtension`, which asks to open the app
///   (prompting for Face ID or the passcode if needed).
/// Either way, the app then runs the user's chosen action.
struct CaptureIntent: CameraCaptureIntent {
    /// Settings the app shares with the capture extension, which can't read the
    /// app's UserDefaults or App Group containers.
    struct Context: Codable, Sendable {
        /// Name of the action Camera Control will run, shown on the Lock Screen.
        var actionName: String?
    }

    typealias AppContext = Context

    static let title: LocalizedStringResource = "Camera Control Action"
    static let description = IntentDescription("Runs the action chosen in CamControl.")

    @MainActor
    func perform() async throws -> some IntentResult {
        #if !CAPTURE_EXTENSION
        LaunchRouter.shared.cameraControlPressed()
        #endif
        return .result()
    }
}
