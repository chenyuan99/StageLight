import SwiftUI

enum StageLayout {
    static func collectionColumnCount(width: CGFloat, regular: Bool, accessibility: Bool) -> Int {
        if accessibility { return 1 }
        guard regular else { return 2 }
        return max(1, min(6, Int((max(0, width - 32) + 16) / 196)))
    }
}

private struct ReadableStageContent: ViewModifier {
    @Environment(\.horizontalSizeClass) private var sizeClass

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: sizeClass == .regular ? 760 : .infinity)
            .frame(maxWidth: .infinity)
    }
}

extension View {
    func readableStageContent() -> some View {
        modifier(ReadableStageContent())
    }
}
