import SwiftUI
import UIKit
import XCTest
@testable import StageLight

@MainActor
final class StagePhotoLayoutTests: XCTestCase {
    func testLandscapeAndPortraitPhotosDoNotWidenScrollContent() {
        for imageSize in [CGSize(width: 1920, height: 1080), CGSize(width: 1080, height: 1920)] {
            let image = UIGraphicsImageRenderer(size: imageSize).image { context in
                UIColor.blue.setFill()
                context.fill(CGRect(origin: .zero, size: imageSize))
            }
            for width in [320.0, 393.0, 402.0, 760.0] {
                for mode in [ContentMode.fit, .fill] {
                    let view = VStack(alignment: .leading) {
                        Text("STRANGER THINGS The First Shadow")
                            .font(.largeTitle)
                        StagePhotoView(image: image, contentMode: mode)
                            .frame(height: 280)
                        Text("MARQUIS THEATRE · New York")
                    }
                    .padding(24)
                    let host = UIHostingController(rootView: view)
                    let size = host.sizeThatFits(in: CGSize(width: width, height: 2000))
                    XCTAssertLessThanOrEqual(size.width, width + 0.5,
                        "Photo \(imageSize), mode \(mode), viewport \(width)")
                }
            }
        }
    }
}
