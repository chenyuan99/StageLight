// swift-tools-version: 6.0
import PackageDescription
let package = Package(name: "MiniTheatreCore",
    products: [.library(name: "MiniTheatreCore", targets: ["MiniTheatreCore"])],
    targets: [.target(name: "MiniTheatreCore"),
              .testTarget(name: "MiniTheatreCoreTests", dependencies: ["MiniTheatreCore"])])
