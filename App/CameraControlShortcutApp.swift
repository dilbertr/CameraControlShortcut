import AVKit
import LockedCameraCapture
import SwiftUI

@main
struct CameraControlShortcutApp: App {
    @StateObject private var store = ActionStore()
    @ObservedObject private var router = LaunchRouter.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(router)
        }
    }
}

/// Runs the active action whenever Camera Control launches the app, otherwise shows settings.
///
/// iOS reports a Camera Control launch (via `CaptureIntent.perform()` or the Lock
/// Screen extension's hand-off) slightly after the app becomes active, so the app
/// starts on a splash that matches the launch screen. If no press arrives within
/// `pressGracePeriod`, it fades to the menu; if one does, the splash stays up while
/// the action runs.
struct RootView: View {
    @EnvironmentObject private var store: ActionStore
    @EnvironmentObject private var router: LaunchRouter
    @Environment(\.scenePhase) private var scenePhase

    @State private var showingSplash = true
    @State private var runningAction: ButtonAction?
    @State private var revealMenuTask: Task<Void, Never>?
    @State private var failedAction: ButtonAction?

    private static let pressGracePeriod: Duration = .milliseconds(500)
    /// How long an automation action keeps CamControl open before going home, so
    /// the "CamControl is opened" automation has time to start.
    private static let automationHandOffDelay: Duration = .seconds(1)

    var body: some View {
        ZStack {
            ContentView(runAction: run)
            if showingSplash {
                SplashView(action: runningAction)
                    .transition(.opacity)
            }
        }
        // The system kills apps launched by Camera Control that neither use the
        // camera nor listen for capture events, so always listen.
        .onCameraCaptureEvent { _ in }
        .alert("Couldn't open", isPresented: .constant(failedAction != nil), presenting: failedAction) { _ in
            Button("OK") {
                failedAction = nil
                showMenu()
            }
        } message: { action in
            Text("“\(action.name)” couldn't be opened. Check that the app is installed, or the shortcut name matches exactly.")
        }
        // Pressed on the Lock Screen: the extension hands off here after unlocking.
        .onContinueUserActivity(NSUserActivityTypeLockedCameraCapture) { _ in
            router.cameraControlPressed()
        }
        // Lets the Lock Screen extension show which action it's about to run.
        .task(id: store.activeAction?.name) {
            try? await CaptureIntent.updateAppContext(.init(actionName: store.activeAction?.name))
        }
        .onChange(of: router.pendingPress) { runPendingPress() }
        .onChange(of: scenePhase, initial: true) { _, phase in
            switch phase {
            case .active:
                if !runPendingPress() { revealMenuSoon() }
            case .background:
                // Next time the app comes forward it may be from a press, so don't
                // let the menu be the first thing shown.
                revealMenuTask?.cancel()
                runningAction = nil
                showingSplash = true
            default:
                break
            }
        }
    }

    @discardableResult
    private func runPendingPress() -> Bool {
        guard scenePhase == .active, router.consumePress() else { return false }
        guard let action = store.activeAction else {
            // Nothing chosen yet: show the menu so one can be added.
            showMenu()
            return true
        }
        revealMenuTask?.cancel()
        withAnimation(.easeOut(duration: 0.2)) {
            runningAction = action
            showingSplash = true
        }
        run(action)
        return true
    }

    private func revealMenuSoon() {
        guard showingSplash, runningAction == nil else { return }
        revealMenuTask?.cancel()
        revealMenuTask = Task {
            try? await Task.sleep(for: Self.pressGracePeriod)
            guard !Task.isCancelled, runningAction == nil else { return }
            showMenu()
        }
    }

    private func showMenu() {
        withAnimation(.easeOut(duration: 0.25)) {
            showingSplash = false
            runningAction = nil
        }
    }

    private func run(_ action: ButtonAction) {
        if action.kind == .automation {
            Task {
                try? await Task.sleep(for: Self.automationHandOffDelay)
                // Skip if the user has already switched away.
                guard UIApplication.shared.applicationState == .active else { return }
                goToHomeScreen()
            }
            return
        }
        guard let url = action.launchURL else {
            failedAction = action
            return
        }
        UIApplication.shared.open(url) { opened in
            if !opened { failedAction = action }
        }
    }

    /// Sends CamControl to the background, like pressing the Home Screen gesture.
    /// Uses UIApplication's private `suspend` method (fine for a sideloaded app).
    private func goToHomeScreen() {
        UIControl().sendAction(#selector(URLSessionTask.suspend), to: UIApplication.shared, for: nil)
    }
}
