import PhotosUI
import SwiftUI
import UIKit

enum AddPerformanceState {
    case sourceSelection
    case camera
    case processing
    case recognitionResult
    case editing
    case saving
    case completed
    case failed(String)
}

@MainActor
struct AddPerformanceFlow: View {
    @Environment(LibraryStore.self) private var library
    @Environment(\.dismiss) private var dismiss

    private let performance: Performance?
    @State private var state: AddPerformanceState
    @State private var draft: PerformanceDraft
    @State private var selectedImages: [UIImage] = []
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var errorMessage: String?
    @State private var duplicateMatch: Performance?
    @State private var showsDuplicateWarning = false
    @State private var recognitionConfidence: Double?
    @State private var showsTheatreSearch = false

    init(editing performance: Performance? = nil) {
        self.performance = performance
        _draft = State(initialValue: performance.map(PerformanceDraft.init) ?? PerformanceDraft())
        _state = State(initialValue: performance == nil ? .sourceSelection : .editing)
    }

    var body: some View {
        NavigationStack {
            Group {
                switch state {
                case .sourceSelection:
                    sourceSelection
                case .camera:
                    CameraPicker(
                        onImage: { image in
                            selectedImages = [image]
                            recognize(image)
                        },
                        onCancel: { state = .sourceSelection }
                    )
                    .ignoresSafeArea()
                    .overlay(alignment: .top) {
                        Text("Point your camera at a Playbill, ticket, or poster.")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(.black.opacity(0.65), in: Capsule())
                            .padding(.top, 12)
                    }
                case .processing:
                    recognitionLoading
                case .recognitionResult:
                    recognitionResult
                case .editing:
                    editor
                case .saving:
                    savingView
                case .completed:
                    Color.clear
                case let .failed(message):
                    failureView(message: message)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isCamera {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
            }
        }
        .interactiveDismissDisabled(isSaving)
        .confirmationDialog(
            "Possible duplicate",
            isPresented: $showsDuplicateWarning,
            titleVisibility: .visible
        ) {
            Button("Save Anyway") { persist() }
            Button("Keep Editing", role: .cancel) { state = .editing }
        } message: {
            Text(duplicateMessage)
        }
        .alert(
            "Couldn't save performance",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .onChange(of: pickerItems) { _, newItems in
            guard !newItems.isEmpty else { return }
            loadPickerItems(newItems)
        }
    }

    private var sourceSelection: some View {
        VStack(alignment: .leading, spacing: 30) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Add to Your Stage")
                    .font(.system(.largeTitle, design: .serif, weight: .semibold))
                Text("Begin with a photo or add the details yourself.")
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 12) {
                sourceButton(
                    title: "Scan",
                    detail: "Use your camera",
                    symbol: "viewfinder"
                ) {
                    Task {
                        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
                            errorMessage = String(localized: "Camera isn't available on this device. Choose a photo or add manually.")
                            return
                        }
                        if await CameraAuthorization.requestAccess() {
                            state = .camera
                        } else {
                            errorMessage = String(localized: "Camera access is off. You can choose a photo or add manually.")
                        }
                    }
                }

                PhotosPicker(
                    selection: $pickerItems,
                    maxSelectionCount: 10,
                    matching: .images
                ) {
                    PhotoLibraryPickerLabel()
                }
                .buttonStyle(.plain)

                sourceButton(
                    title: "Add Manually",
                    detail: "Enter the performance details",
                    symbol: "square.and.pencil"
                ) {
                    state = .editing
                }
                .accessibilityIdentifier("add-manually-button")
            }
            Spacer()
        }
        .padding(24)
        .background(StageTheme.background)
    }

    private func sourceButton(
        title: LocalizedStringKey,
        detail: LocalizedStringKey,
        symbol: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            sourceLabel(title: title, detail: detail, symbol: symbol)
        }
        .buttonStyle(.plain)
    }

    private func sourceLabel(
        title: LocalizedStringKey,
        detail: LocalizedStringKey,
        symbol: String
    ) -> some View {
        HStack(spacing: 16) {
            Image(systemName: symbol)
                .font(.title3)
                .frame(width: 44, height: 44)
                .background(StageTheme.spotlight.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(StageTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contentShape(Rectangle())
    }

    private var recognitionLoading: some View {
        VStack(spacing: 24) {
            ProgressView()
                .controlSize(.large)
            Text("Finding your show…")
                .font(.title2.weight(.medium))
            Button("Add Manually") {
                state = .editing
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(StageTheme.background)
    }

    private var recognitionResult: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                if let firstImage = selectedImages.first {
                    Image(uiImage: firstImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 280)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .clipped()
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text(isLowConfidence ? "Is this your show?" : "We found your show")
                        .font(.title2.weight(.semibold))
                    Text(draft.showTitle.isEmpty ? "Unknown show" : draft.showTitle)
                        .font(.system(.largeTitle, design: .serif, weight: .semibold))
                    if !draft.theatre.isEmpty {
                        Text(draft.theatre).foregroundStyle(.secondary)
                    }
                    Text(draft.date.formatted(date: .long, time: .omitted))
                        .foregroundStyle(.secondary)
                }

                Button("Add to Stage") { requestSave() }
                    .buttonStyle(StagePrimaryButtonStyle())
                    .disabled(draft.showTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Button("Edit details") { state = .editing }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
            }
            .padding(24)
        }
        .background(StageTheme.background)
    }

    private var editor: some View {
        Form {
            Section("Show") {
                TextField("Show title", text: $draft.showTitle)
                    .textInputAutocapitalization(.words)
                    .accessibilityIdentifier("show-title-field")
            }

            Section("When") {
                DatePicker("Date", selection: $draft.date, displayedComponents: .date)
                Toggle("Add a time", isOn: $draft.includesTime)
                if draft.includesTime {
                    DatePicker(
                        "Time",
                        selection: Binding(
                            get: { draft.time ?? draft.date },
                            set: { draft.time = $0 }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                }
            }

            Section("Where") {
                TextField("Theatre", text: $draft.theatre)
                    .textInputAutocapitalization(.words)
                TextField("City", text: $draft.city)
                    .textInputAutocapitalization(.words)
                Button {
                    showsTheatreSearch = true
                } label: {
                    Label("Find Theatre with Apple Maps", systemImage: "map")
                }
            }

            Section("Rating") {
                StageRatingView(rating: $draft.rating, size: 24)
            }

            Section("Seat") {
                TextField("Section", text: $draft.seatSection)
                TextField("Row", text: $draft.seatRow)
                TextField("Seat", text: $draft.seatNumber)
            }

            Section("Notes") {
                TextEditor(text: $draft.notes)
                    .frame(minHeight: 110)
                    .overlay(alignment: .topLeading) {
                        if draft.notes.isEmpty {
                            Text("What will you remember?")
                                .foregroundStyle(.tertiary)
                                .padding(.top, 8)
                                .allowsHitTesting(false)
                        }
                    }
            }

            Section("Photos") {
                if !draft.photoFilenames.isEmpty || !selectedImages.isEmpty {
                    ScrollView(.horizontal) {
                        HStack(spacing: 10) {
                            ForEach(draft.photoFilenames, id: \.self) { filename in
                                photoItem(filename: filename)
                            }
                            ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                                newPhotoItem(index: index, image: image)
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                }

                PhotosPicker(
                    selection: $pickerItems,
                    maxSelectionCount: 10,
                    matching: .images
                ) {
                    AddPhotosPickerLabel()
                }
            }
        }
        .navigationTitle(performance == nil ? "Add Performance" : "Edit Performance")
        .sheet(isPresented: $showsTheatreSearch) {
            TheatreSearchView(
                currentTheatre: draft.theatre,
                cityHint: draft.city
            ) { suggestion in
                draft.applyTheatreSuggestion(suggestion)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button(performance == nil ? "Add to Stage" : "Save Changes") {
                requestSave()
            }
            .buttonStyle(StagePrimaryButtonStyle())
            .accessibilityIdentifier("save-performance-button")
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.bar)
        }
    }

    private func photoItem(filename: String) -> some View {
        ZStack(alignment: .topTrailing) {
            PhotoThumbnailView(
                filename: filename,
                syncedData: draft.photoDataByFilename[filename]
            )
                .frame(width: 100, height: 126)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            Button {
                draft.photoFilenames.removeAll { $0 == filename }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .black.opacity(0.65))
                    .font(.title3)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Remove photo")
        }
    }

    private func newPhotoItem(index: Int, image: UIImage) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 126)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .clipped()
            Button {
                guard selectedImages.indices.contains(index) else { return }
                selectedImages.remove(at: index)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .black.opacity(0.65))
                    .font(.title3)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Remove new photo")
        }
    }

    private var savingView: some View {
        VStack(spacing: 20) {
            ProgressView().controlSize(.large)
            Text("Adding to your stage…")
                .font(.headline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(StageTheme.background)
    }

    private func failureView(message: String) -> some View {
        ContentUnavailableView {
            Label("Recognition unavailable", systemImage: "exclamationmark.circle")
        } description: {
            Text(message)
        } actions: {
            Button("Add Manually") { state = .editing }
                .buttonStyle(.borderedProminent)
            Button("Choose Another Source") { state = .sourceSelection }
        }
    }

    private func loadPickerItems(_ items: [PhotosPickerItem]) {
        let shouldRecognize: Bool
        if case .sourceSelection = state {
            shouldRecognize = true
            state = .processing
        } else {
            shouldRecognize = false
        }
        Task {
            var images: [UIImage] = []
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    images.append(image)
                }
            }
            pickerItems = []
            guard let first = images.first else {
                state = .failed(String(localized: "The selected photo could not be opened."))
                return
            }
            selectedImages.append(contentsOf: images)
            if shouldRecognize {
                recognize(first)
            } else {
                state = .editing
            }
        }
    }

    private func recognize(_ image: UIImage) {
        state = .processing
        Task {
            do {
                let result = try await library.recognitionService.recognize(image: image)
                apply(result)
                state = .recognitionResult
            } catch {
                AppLogger.recognition.notice("Recognition failed: \(error.localizedDescription, privacy: .public)")
                state = .failed(error.localizedDescription)
            }
        }
    }

    private func apply(_ result: RecognitionResult) {
        if let showTitle = result.showTitle { draft.showTitle = showTitle }
        if let theatre = result.theatre { draft.theatre = theatre }
        if let city = result.city { draft.city = city }
        if let date = result.date { draft.date = date }
        if let time = result.time {
            draft.includesTime = true
            draft.time = time
        }
        recognitionConfidence = result.confidence
    }

    private func requestSave() {
        do {
            _ = try draft.validate()
            if performance == nil,
               case let .possible(existing) = library.duplicateCheck(for: draft) {
                duplicateMatch = existing
                showsDuplicateWarning = true
            } else {
                persist()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func persist() {
        state = .saving
        Task {
            do {
                if let performance {
                    try await library.update(
                        performance,
                        draft: draft,
                        newImages: selectedImages
                    )
                } else {
                    try await library.add(draft: draft, images: selectedImages)
                }
                state = .completed
                dismiss()
            } catch {
                state = .editing
                errorMessage = error.localizedDescription
            }
        }
    }

    private var isLowConfidence: Bool {
        (recognitionConfidence ?? 0) < 0.65
    }

    private var duplicateMessage: String {
        guard let duplicateMatch else {
            return String(localized: "You already saved this show on the same day. Matinee and evening performances can both be kept.")
        }
        return String(localized: "A performance is already saved on \(duplicateMatch.date.formatted(date: .long, time: .omitted)). Matinee and evening performances can both be kept.")
    }

    private var isCamera: Bool {
        if case .camera = state { return true }
        return false
    }

    private var isSaving: Bool {
        if case .saving = state { return true }
        return false
    }
}

private struct PhotoLibraryPickerLabel: View {
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle")
                .font(.title3)
                .frame(width: 44, height: 44)
                .background(StageTheme.spotlight.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text("Choose from Photos").font(.headline)
                Text("Select Playbills, tickets, or posters")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(StageTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contentShape(Rectangle())
    }
}

private struct AddPhotosPickerLabel: View {
    var body: some View {
        Label("Add Photos", systemImage: "photo.badge.plus")
            .frame(minHeight: 44)
    }
}
