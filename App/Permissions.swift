import AVFoundation
import SwiftUI

/// iOS greys the app out in Settings → Camera → Camera Control until camera access
/// has been granted, even though CamControl never uses the camera.
@MainActor
final class Permissions: ObservableObject {
    enum Status { case granted, notAsked, denied }

    @Published private(set) var camera: Status = .notAsked

    func refresh() {
        camera = switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: .granted
        case .notDetermined: .notAsked
        default: .denied
        }
    }

    func requestCamera() async {
        _ = await AVCaptureDevice.requestAccess(for: .video)
        refresh()
    }
}

struct PermissionRow: View {
    let title: String
    let symbol: String
    let status: Permissions.Status
    let request: () async -> Void

    var body: some View {
        HStack {
            Label(title, systemImage: symbol)
            Spacer()
            switch status {
            case .granted:
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
            case .notAsked:
                Button("Allow") { Task { await request() } }
                    .buttonStyle(.bordered)
            case .denied:
                Button("Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(.bordered)
                .tint(.orange)
            }
        }
    }
}
