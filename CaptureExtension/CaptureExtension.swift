import AVKit
import ExtensionKit
import LockedCameraCapture
import SwiftUI

/// Runs when Camera Control is pressed on the Lock Screen. It immediately asks the
/// system to open the app (which prompts for Face ID or the passcode if the phone
/// is locked), and the app then runs the chosen action.
@main
struct CaptureExtension: LockedCameraCaptureExtension {
    var body: some LockedCameraCaptureExtensionScene {
        LockedCameraCaptureUIScene { session in
            HandOffView(session: session)
        }
    }
}

private struct HandOffView: View {
    let session: LockedCameraCaptureSession
    @State private var actionName: String?
    @State private var failed = false

    var body: some View {
        SplashBackdrop {
            if failed {
                Button {
                    Task { await openApp() }
                } label: {
                    Text(actionName.map { "Unlock to open \($0)" } ?? "Unlock to continue")
                }
                .buttonStyle(.borderedProminent)
                .tint(.white.opacity(0.2))
            }
        }
        // The system terminates capture extensions that don't listen for capture events.
        .onCameraCaptureEvent { event in
            if event.phase == .ended { Task { await openApp() } }
        }
        .task {
            actionName = (try? await CaptureIntent.appContext)?.actionName
            await openApp()
        }
    }

    private func openApp() async {
        do {
            failed = false
            try await session.openApplication(for: NSUserActivity(activityType: NSUserActivityTypeLockedCameraCapture))
        } catch {
            // E.g. the passcode prompt was cancelled.
            failed = true
        }
    }
}
