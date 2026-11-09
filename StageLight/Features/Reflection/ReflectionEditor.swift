import SwiftUI

struct ReflectionEditor: View {
    @Environment(LibraryStore.self) private var library
    @Environment(\.dismiss) private var dismiss
    let performance: Performance
    let onSaved: () -> Void
    @State private var original: String
    @State private var draft: String
    @State private var discarding = false
    @State private var error: String?
    @State private var showsLatest = false

    init(performance: Performance, onSaved: @escaping () -> Void) {
        self.performance = performance
        self.onSaved = onSaved
        _original = State(initialValue: performance.notes)
        _draft = State(initialValue: performance.notes)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(performance.show?.title ?? "").font(.headline)
                    Text("What stayed with you?").foregroundStyle(.secondary)
                    TextEditor(text: $draft)
                        .frame(minHeight: 200)
                        .accessibilityLabel("Your memory")
                        .accessibilityIdentifier("reflection-editor")
                } footer: {
                    Text("Optional and private. Share only when you choose.")
                }
                if let error {
                    Section {
                        Text(error).foregroundStyle(.red)
                        ShareLink("Copy or share draft", item: draft)
                        if library.performances.contains(where: { $0.id == performance.id }) {
                            Button("Review latest note") { library.refresh(); showsLatest = true }
                        }
                    }
                }
            }
            .navigationTitle("Add a memory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if draft != original { discarding = true } else { dismiss() }
                    }.accessibilityIdentifier("reflection-cancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.accessibilityIdentifier("reflection-save")
                }
            }
            .interactiveDismissDisabled(draft != original)
            .alert("Discard unsaved changes?", isPresented: $discarding) {
                Button("Discard Changes", role: .destructive) { dismiss() }
                Button("Keep Editing", role: .cancel) {}
            }
            .sheet(isPresented: $showsLatest) {
                NavigationStack {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            Text("Latest saved note").font(.headline)
                            Text(performance.notes).textSelection(.enabled)
                            Text("Your draft").font(.headline)
                            Text(draft).textSelection(.enabled)
                            Button("Combine latest and draft") {
                                let latest = performance.notes
                                draft = [latest, draft].filter { !$0.isEmpty }.joined(separator: "\n\n")
                                original = latest
                                error = nil
                                showsLatest = false
                            }
                            Text("Review the combined text, then save. Both versions are kept in the editor.")
                                .font(.footnote).foregroundStyle(.secondary)
                        }.padding()
                    }
                    .navigationTitle("Review changes")
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showsLatest = false } } }
                }
            }
        }
    }

    private func save() {
        do {
            try library.updateNotes(performance, notes: draft, expectedNotes: original)
            original = draft
            onSaved()
            dismiss()
        } catch { self.error = error.localizedDescription }
    }
}

struct ReflectionSettings: View {
    @AppStorage(ReflectionPolicy.enabledKey) private var enabled = false
    @AppStorage("diary.showUpcoming") private var showsUpcoming = true
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Diary preferences").font(.headline)
            Toggle("Show upcoming section", isOn: $showsUpcoming)
            Toggle("Offer post-show reflection", isOn: $enabled)
                .accessibilityIdentifier("reflection-setting")
            Text("After you mark a booking attended, offer a moment to write. No reminders or notifications.")
                .font(.footnote).foregroundStyle(.secondary)
        }
    }
}
