import SwiftUI

struct StageRatingView: View {
    @Binding var rating: Double?
    var size: CGFloat = 28

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: symbol(for: index))
                    .font(.system(size: size, weight: .medium))
                    .foregroundStyle(StageTheme.spotlight)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                    .gesture(
                        SpatialTapGesture().onEnded { value in
                            rating = Double(index) - (value.location.x < 22 ? 0.5 : 0)
                        }
                    )
                    .accessibilityHidden(true)
            }

            if rating != nil {
                Button {
                    rating = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 44, minHeight: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear rating")
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rating")
        .accessibilityValue(accessibilityValue)
        .accessibilityHint("Swipe up or down to adjust in half-star steps")
        .accessibilityAdjustableAction { direction in
            let current = rating ?? 0
            switch direction {
            case .increment:
                rating = min(5, current + 0.5)
            case .decrement:
                let next = current - 0.5
                rating = next < 0.5 ? nil : next
            @unknown default:
                break
            }
        }
    }

    private func symbol(for index: Int) -> String {
        let value = rating ?? 0
        if value >= Double(index) { return "star.fill" }
        if value >= Double(index) - 0.5 { return "star.leadinghalf.filled" }
        return "star"
    }

    private var accessibilityValue: String {
        guard let rating else { return AppLanguage.localized("Not rated") }
        return AppLanguage.localized("\(rating.formatted()) out of 5 stars")
    }
}

struct RatingLabel: View {
    let rating: Double

    var body: some View {
        Label(rating.formatted(.number.precision(.fractionLength(1))), systemImage: "star.fill")
            .font(.caption)
            .foregroundStyle(.secondary)
            .accessibilityLabel("\(rating.formatted()) out of 5 stars")
    }
}
