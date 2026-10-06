// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "DiceKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "DiceKit", targets: ["DiceKit"]),
    ],
    targets: [
        .target(name: "DiceKit"),
        .testTarget(name: "DiceKitTests", dependencies: ["DiceKit"]),
    ]
)
