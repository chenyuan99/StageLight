import SwiftUI

struct PerformanceDetailView: View {
    @Environment(LibraryStore.self) private var library
    @Environment(\.dismiss) private var dismiss
    let performance: Performance
    @State private var isEditing = false
    @State private var isSharingMemory = false
    @State private var confirmsDelete = false

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

                if let first = photos.first {
                    PhotoThumbnailView(photo: first)
                        .frame(height: 390)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                detailMetadata

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
