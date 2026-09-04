import SwiftUI
import UIKit

struct MemoryCardComposerView: View {
    @Environment(LibraryStore.self) private var library
    @Environment(\.dismiss) private var dismiss

    let performance: Performance

    @State private var template = MemoryCardTemplate.spotlight
    @State private var options: MemoryCardOptions
    @State private var selectedPhotoID: UUID?
    @State private var selectedImage: UIImage?
    @State private var includesAppStoreLink = true
    @State private var sharedCard: SharedMemoryCard?
    @State private var errorMessage: String?

    private var photos: [PerformancePhoto] {
        performance.photoList.sorted { $0.sortOrder < $1.sortOrder }
    }

    private var content: MemoryCardContent {
        .make(source: MemoryCardSource(performance: performance), options: options)
    }

    init(performance: Performance) {
        self.performance = performance
        let firstPhotoID = performance.photoList.min { $0.sortOrder < $1.sortOrder }?.id
        _selectedPhotoID = State(initialValue: firstPhotoID)
        _options = State(initialValue: MemoryCardOptions(includesPhoto: firstPhotoID != nil))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    MemoryCardPreview(content: content, template: template, photo: selectedImage)
                        .frame(maxHeight: 520)
                        .shadow(color: .black.opacity(0.14), radius: 18, y: 10)
                        .accessibilityIdentifier("memory-card-preview")

                    VStack(alignment: .leading, spacing: 18) {
                        Picker("Design", selection: $template) {
                            ForEach(MemoryCardTemplate.allCases) { template in
                                Text(template.displayName).tag(template)
                            }
                        }
                        .pickerStyle(.segmented)

                        if photos.count > 1 {
                            photoChooser
                        }

                        DisclosureGroup("Included details") {
                            VStack(spacing: 12) {
                                Toggle("Show title", isOn: $options.includesTitle)
                                Toggle("Photo", isOn: $options.includesPhoto)
                                    .disabled(photos.isEmpty)
                                Toggle("Date", isOn: $options.includesDate)
                                Toggle("Theatre and city", isOn: $options.includesVenue)
                                Toggle("Seat", isOn: $options.includesSeat)
                                Toggle("Rating", isOn: $options.includesRating)
                                Toggle("Note", isOn: $options.includesNote)
                            }
                            .padding(.top, 12)
                        }
                        .font(.body.weight(.medium))

                        Toggle("Include App Store link", isOn: $includesAppStoreLink)
                        Text("The link is shared separately when the destination supports it. It contains no tracking code.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(18)
                    .background(StageTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .padding(16)
                .padding(.bottom, 88)
            }
            .background(StageTheme.background)
            .navigationTitle("Share Memory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button("Share Card", systemImage: "square.and.arrow.up") {
                    renderForSharing()
                }
                .buttonStyle(StagePrimaryButtonStyle())
                .accessibilityIdentifier("share-memory-card")
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
            }
        }
        .task(id: selectedPhotoID) {
            await loadSelectedPhoto()
        }
        .sheet(item: $sharedCard) { card in
            MemoryCardActivityView(
                image: card.image,
                includesAppStoreLink: card.includesAppStoreLink
            )
        }
        .alert("Unable to Share", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "The memory card could not be prepared.")
        }
    }

    private var photoChooser: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Photo")
                .font(.subheadline.weight(.semibold))

            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(photos) { photo in
                        Button {
                            selectedPhotoID = photo.id
                            options.includesPhoto = true
                        } label: {
                            PhotoThumbnailView(photo: photo)
                                .frame(width: 72, height: 86)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(
                                            selectedPhotoID == photo.id ? Color.primary : .clear,
                                            lineWidth: 3
                                        )
                                }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Use photo \(photo.sortOrder + 1)")
                        .accessibilityAddTraits(selectedPhotoID == photo.id ? .isSelected : [])
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    private func loadSelectedPhoto() async {
        guard let selectedPhotoID,
              let photo = photos.first(where: { $0.id == selectedPhotoID }) else {
            selectedImage = nil
            return
        }

        if let data = photo.imageData, let image = UIImage(data: data) {
            selectedImage = image
            return
        }

        selectedImage = try? await library.photoStore.load(filename: photo.filename)
    }

    private func renderForSharing() {
        guard let image = renderedCard() else {
            errorMessage = String(localized: "The memory card could not be prepared.")
            return
        }
        sharedCard = SharedMemoryCard(
            image: image,
            includesAppStoreLink: includesAppStoreLink
        )
    }

    private func renderedCard() -> UIImage? {
        MemoryCardRenderer.render(
            content: content,
            template: template,
            photo: selectedImage
        )
    }
}

private struct MemoryCardPreview: View {
    let content: MemoryCardContent
    let template: MemoryCardTemplate
    let photo: UIImage?

    var body: some View {
        GeometryReader { proxy in
            let canvas = template.canvasSize
            let scale = min(proxy.size.width / canvas.width, proxy.size.height / canvas.height)

            MemoryCardView(content: content, template: template, photo: photo)
                .scaleEffect(scale)
                .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
        .aspectRatio(template.canvasSize.width / template.canvasSize.height, contentMode: .fit)
        .animation(.easeInOut(duration: 0.2), value: template)
    }
}

private struct SharedMemoryCard: Identifiable {
    let id = UUID()
    let image: UIImage
    let includesAppStoreLink: Bool
}

private struct MemoryCardActivityView: UIViewControllerRepresentable {
    let image: UIImage
    let includesAppStoreLink: Bool

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: MemoryCardBrand.activityItems(
                image: image,
                includesAppStoreLink: includesAppStoreLink
            ),
            applicationActivities: [MemoryCardSaveToPhotosActivity()]
        )
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
