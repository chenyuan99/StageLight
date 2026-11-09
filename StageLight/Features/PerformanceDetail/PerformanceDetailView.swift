import SwiftUI

struct PerformanceDetailView: View {
    @Environment(LibraryStore.self) private var library
    @Environment(\.dismiss) private var dismiss
    let performance: Performance
    @State private var isEditing = false
    @State private var isSharingMemory = false
    @State private var confirmsDelete = false
    @State private var confirmsCancel = false
    @State private var editingReflection = false
    @State private var offersReflection = false
    @State private var actionError: String?
    @AppStorage(ReflectionPolicy.enabledKey) private var reflectionEnabled = false

    private var photos: [PerformancePhoto] {
        performance.photoList.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 7) {
                    Text(performance.date.formatted(date: .complete, time: .omitted))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                    Text(performance.show?.title ?? "Untitled Show")
                        .font(.system(.largeTitle, design: .serif, weight: .semibold))
                    venueLine
                }

                bookingActions
                if offersReflection && reflectionEnabled {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What stayed with you?").font(.headline)
                        Text("A sentence is enough. You can always return later.").foregroundStyle(.secondary)
                        HStack {
                            Button("Add a memory") { editingReflection = true }
                                .buttonStyle(.borderedProminent).tint(MiniPalette.accent)
                                .accessibilityIdentifier("reflection-offer")
                            Button("Not now") { offersReflection = false }
                        }
                    }.padding().frame(maxWidth: .infinity, alignment: .leading)
                        .background(StageTheme.surface, in: RoundedRectangle(cornerRadius: 16))
                }
                if let actionError { Text(actionError).foregroundStyle(.red) }
                if let first = photos.first {
                    PhotoThumbnailView(photo: first, contentMode: .fit)
                        .frame(height: 390)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                detailMetadata

                Button(performance.notes.isEmpty ? "Add notes" : "Edit notes") { editingReflection = true }
                    .accessibilityIdentifier("edit-reflection")
                if !performance.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("What I remember")
                            .font(.headline)
                        Text(performance.notes)
                            .font(.body)
                            .textSelection(.enabled)
                    }
                }

                if photos.count > 1 {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Photos")
                            .font(.headline)
                        ScrollView(.horizontal) {
                            LazyHStack(spacing: 12) {
                                ForEach(photos.dropFirst()) { photo in
                                    PhotoThumbnailView(photo: photo)
                                        .frame(width: 180, height: 220)
                                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                }
                            }
                        }
                        .scrollIndicators(.hidden)
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 40)
            .readableStageContent()
        }
        .background(StageTheme.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Share Memory", systemImage: "square.and.arrow.up") {
                        isSharingMemory = true
                    }
                    Button("Edit", systemImage: "pencil") { isEditing = true }
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        confirmsDelete = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Performance actions")
                .accessibilityIdentifier("performance-actions")
            }
        }
        .sheet(isPresented: $editingReflection) {
            ReflectionEditor(performance: performance) { offersReflection = false }
        }
        .confirmationDialog("Cancel this booking?", isPresented: $confirmsCancel, titleVisibility: .visible) {
            Button("Cancel booking", role: .destructive) { changeStatus("cancelled") }
                .accessibilityIdentifier("confirm-cancel-booking")
            Button("Keep booking", role: .cancel) {}
        } message: { Text("Your notes, photos and booking details will be kept.") }
        .sheet(isPresented: $isEditing) {
            AddPerformanceFlow(editing: performance)
        }
        .sheet(isPresented: $isSharingMemory) {
            MemoryCardComposerView(performance: performance)
        }
        .confirmationDialog(
            "Delete this performance?",
            isPresented: $confirmsDelete,
            titleVisibility: .visible
        ) {
            Button("Delete Performance", role: .destructive) {
                do {
                    try library.delete(performance)
                    dismiss()
                } catch {
                    library.errorMessage = error.localizedDescription
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Its photos and notes will be removed from this device.")
        }
    }

    @ViewBuilder
    private var bookingActions: some View {
        if !performance.isAttended {
            VStack(alignment: .leading, spacing: 12) {
                Label(LocalizedStringKey(performance.statusLabel), systemImage: "calendar")
                    .font(.headline).foregroundStyle(MiniPalette.accent)
                if performance.isUpcoming {
                    if Calendar.current.startOfDay(for: performance.date) < Calendar.current.startOfDay(for: .now) {
                        Text("Needs attendance confirmation").font(.subheadline).foregroundStyle(.secondary)
                    }
                    Button("Mark attended") { changeStatus("attended") }
                        .buttonStyle(.borderedProminent).tint(MiniPalette.accent)
                        .accessibilityIdentifier("mark-attended")
                    HStack {
                        Button("Reschedule") { isEditing = true }
                        Spacer()
                        Button("Cancel booking") { confirmsCancel = true }
                            .accessibilityIdentifier("cancel-booking")
                    }
                } else if performance.statusRaw == "cancelled" {
                    Button("Restore booking") { changeStatus("upcoming") }
                        .accessibilityIdentifier("restore-booking")
                }
            }.padding().frame(maxWidth: .infinity, alignment: .leading)
                .background(StageTheme.surface, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    private func changeStatus(_ status: String) {
        let wasUpcoming = performance.isUpcoming
        do {
            try library.transition(performance, to: status)
            actionError = nil
            if wasUpcoming && status == "attended" {
                offersReflection = ReflectionPolicy.consumeOffer(for: performance.id)
            }
        } catch { actionError = error.localizedDescription }
    }

    @ViewBuilder
    private var venueLine: some View {
        let pieces = [performance.theatre, performance.city].filter { !$0.isEmpty }
        if !pieces.isEmpty {
            Text(pieces.joined(separator: " · "))
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    private var detailMetadata: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let rating = performance.rating {
                LabeledContent("Rating") { RatingLabel(rating: rating) }
            }
            if let time = performance.time {
                LabeledContent("Time", value: time.formatted(date: .omitted, time: .shortened))
            }
            if let seat = performance.formattedSeat {
                LabeledContent("Seat", value: seat)
            }
        }
    }
}
