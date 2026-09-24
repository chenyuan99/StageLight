import SwiftUI
import UIKit

/// The container owns layout; a photo's aspect ratio must never widen its parent.
struct StagePhotoView: View {
    let image: UIImage
    var contentMode: ContentMode = .fit

    var body: some View {
        Color.clear
            .overlay {
                GeometryReader { geometry in
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
            .clipped()
    }
}
