import SwiftUI

struct ContentView: View {
    let runAction: (ButtonAction) -> Void

    @EnvironmentObject private var store: ActionStore
    @StateObject private var permissions = Permissions()
    @Environment(\.scenePhase) private var scenePhase

    @State private var editing: ButtonAction?
    @State private var isAddingNew = false

    var body: some View {
        NavigationStack {
            List {
                actionsSection
                testSection
                permissionsSection
                setupSection
            }
            .navigationTitle("Camera Control")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isAddingNew = true
                        editing = ButtonAction(name: "", kind: .shortcut)
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $editing) { action in
                ActionEditorView(action: action, isNew: isAddingNew, test: runAction) { saved in
                    store.upsert(saved)
                    if isAddingNew { store.activeID = saved.id }
                }
            }
        }
        .onAppear { permissions.refresh() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { permissions.refresh() }
        }
    }

    // MARK: Sections

    private var actionsSection: some View {
        Section {
            ForEach(store.actions) { action in
                ActionRow(action: action, isActive: action.id == store.activeID)
                    .contentShape(Rectangle())
                    .onTapGesture { store.activeID = action.id }
                    .swipeActions {
                        Button(role: .destructive) { store.delete(action) } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        Button { edit(action) } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                    .contextMenu {
                        Button { runAction(action) } label: { Label("Test", systemImage: "play.fill") }
                        Button(role: .destructive) { store.delete(action) } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
            .onMove(perform: store.move)
            .onDelete { offsets in
                offsets.map { store.actions[$0] }.forEach(store.delete)
            }

            Button {
                isAddingNew = true
                editing = ButtonAction(name: "", kind: .shortcut)
            } label: {
                Label("Add Action", systemImage: "plus.circle.fill")
            }
        } header: {
            Text("Pressing Camera Control will")
        } footer: {
            Text("Tap an action to use it. Swipe left to edit or delete. On the Lock Screen, you'll be asked to unlock first.")
        }
    }

    @ViewBuilder
    private var testSection: some View {
        if let active = store.activeAction {
            Section {
                Button {
                    runAction(active)
                } label: {
                    Label("Test “\(active.name)”", systemImage: "play.fill")
                }
            }
        }
    }

    private var permissionsSection: some View {
        Section {
            PermissionRow(title: "Camera", symbol: "camera", status: permissions.camera, request: permissions.requestCamera)
        } header: {
            Text("Permissions")
        } footer: {
            Text("CamControl never uses the camera, but iOS won't let you pick it for Camera Control without this.")
        }
    }

    private var setupSection: some View {
        Section("Setup") {
            SetupStep(number: 1, text: "Allow camera access above.")
            SetupStep(number: 2, text: "Open Settings → Camera → Camera Control.")
            SetupStep(number: 3, text: "Under Launch Camera, choose CamControl.")
            Button("Open Settings") {
                // Deep-links to the Settings app (root); Camera settings are a couple of taps from there.
                if let url = URL(string: "App-prefs:") { UIApplication.shared.open(url) }
            }
        }
    }

    private func edit(_ action: ButtonAction) {
        isAddingNew = false
        editing = action
    }
}

private struct ActionRow: View {
    let action: ButtonAction
    let isActive: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(color, in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(action.name)
                    .foregroundStyle(.primary)
                Text(action.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if isActive {
                Image(systemName: "checkmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.tint)
            }
        }
        .padding(.vertical, 2)
    }

    private var symbol: String {
        if action.kind == .openApp, let app = AppCatalog.app(forURL: action.value) {
            return app.symbol
        }
        return action.kind.symbol
    }

    private var color: Color {
        switch action.kind {
        case .openApp: return .blue
        case .shortcut: return .indigo
        case .url: return .orange
        case .automation: return .purple
        }
    }
}

private struct SetupStep: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text("\(number)")
                .font(.caption.weight(.bold))
                .frame(width: 22, height: 22)
                .background(.tint.opacity(0.15), in: Circle())
            Text(text)
        }
    }
}
