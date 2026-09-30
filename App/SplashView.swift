import SwiftUI

/// Shown while Camera Control launches an action.
struct SplashView: View {
    /// The action being run, or nil while still waiting to find out.
    let action: ButtonAction?

    var body: some View {
        SplashBackdrop {
            if let action {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(.white.opacity(0.7))
                    Text(action.kind == .automation ? "Running \(action.name)…" : "Opening \(action.name)…")
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.7))
                .transition(.opacity)
            }
        }
    }
}
