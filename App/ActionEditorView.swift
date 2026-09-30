import SwiftUI

struct ActionEditorView: View {
    let isNew: Bool
    let test: (ButtonAction) -> Void
    let onSave: (ButtonAction) -> Void

    @State private var draft: ButtonAction
    @Environment(\.dismiss) private var dismiss

    init(action: ButtonAction, isNew: Bool, test: @escaping (ButtonAction) -> Void, onSave: @escaping (ButtonAction) -> Void) {
        _draft = State(initialValue: action)
        self.isNew = isNew
        self.test = test
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Type", selection: $draft.kind) {
                        ForEach(ButtonAction.Kind.allCases) { kind in
                            Text(kind.shortTitle).tag(kind)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }

                switch draft.kind {
                case .openApp: appFields
                case .shortcut: shortcutFields
                case .url: urlFields
                case .automation: automationFields
                }

                Section("Name") {
                    TextField(suggestedName.isEmpty ? "Name" : suggestedName, text: $draft.name)
                }

                Section {
                    Button {
                        test(finalized)
                    } label: {
                        Label("Test", systemImage: "play.fill")
                    }
                    .disabled(!draft.isRunnable)
                }
            }
            .navigationTitle(isNew ? "New Action" : "Edit Action")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(finalized)
                        dismiss()
                    }
                    .disabled(!draft.isRunnable)
                }
            }
            .onChange(of: draft.kind) {
                draft.value = ""
                draft.shortcutInput = ""
            }
        }
    }

    // MARK: Fields

    @ViewBuilder
    private var appFields: some View {
        Section("Apple Apps") {
            ForEach(AppCatalog.apple) { appRow($0) }
        }
        Section("Other Apps") {
            ForEach(AppCatalog.thirdParty) { appRow($0) }
        }
        Section {
            TextField("myapp://", text: $draft.value)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .clearButton(text: $draft.value)
        } header: {
            Text("Or enter a URL scheme")
        } footer: {
            Text("iOS only lets apps open other apps through URL schemes. If an app has none, create a shortcut with an “Open App” step and use Run Shortcut instead.")
        }
    }

    private func appRow(_ app: AppCatalog.App) -> some View {
        Button {
            draft.value = app.url
        } label: {
            HStack {
                Label(app.name, systemImage: app.symbol)
                    .foregroundStyle(.primary)
                Spacer()
                if draft.value == app.url {
                    Image(systemName: "checkmark").foregroundStyle(.tint)
                }
            }
        }
    }

    @ViewBuilder
    private var shortcutFields: some View {
        Section {
            TextField("Shortcut name", text: $draft.value)
                .autocorrectionDisabled()
        } header: {
            Text("Shortcut")
        } footer: {
            Text("Must match the name in the Shortcuts app exactly, including capitalization.")
        }
        Section {
            TextField("Optional", text: $draft.shortcutInput)
        } header: {
            Text("Input text")
        } footer: {
            Text("Passed to the shortcut as its input.")
        }
    }

    @ViewBuilder
    private var urlFields: some View {
        Section {
            TextField("https://example.com", text: $draft.value)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .clearButton(text: $draft.value)
        } header: {
            Text("URL")
        } footer: {
            Text("Web links open in Safari, or in their app if it handles the link.")
        }
    }

    @ViewBuilder
    private var automationFields: some View {
        Section {
            SetupStepRow(number: 1, text: "In Shortcuts, go to Automation and tap +.")
            SetupStepRow(number: 2, text: "Choose App, pick CamControl, and select “Is Opened”.")
            SetupStepRow(number: 3, text: "Select “Run Immediately” and turn off “Notify When Run”.")
            SetupStepRow(number: 4, text: "Add the actions you want, e.g. Run Shortcut.")
            Button {
                if let url = URL(string: "shortcuts://") { UIApplication.shared.open(url) }
            } label: {
                Label("Open Shortcuts", systemImage: "arrow.up.forward.app")
            }
        } header: {
            Text("Set up in Shortcuts")
        } footer: {
            Text("After a button press, CamControl shows its splash while the automation starts, then goes to the Home Screen. The automation also runs whenever you open CamControl yourself.")
        }
    }

    // MARK: Helpers

    private var suggestedName: String {
        let value = draft.value.trimmingCharacters(in: .whitespacesAndNewlines)
        switch draft.kind {
        case .openApp: return AppCatalog.app(forURL: value)?.name ?? value
        case .shortcut: return value
        case .url: return draft.launchURL?.host() ?? value
        case .automation: return "Automation"
        }
    }

    private var finalized: ButtonAction {
        var action = draft
        action.name = action.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if action.name.isEmpty { action.name = suggestedName }
        return action
    }
}

private extension View {
    /// Adds an ⓧ button that empties `text`, shown whenever there's something to clear.
    func clearButton(text: Binding<String>) -> some View {
        HStack {
            self
            if !text.wrappedValue.isEmpty {
                Button {
                    text.wrappedValue = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Clear")
            }
        }
    }
}

private struct SetupStepRow: View {
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
