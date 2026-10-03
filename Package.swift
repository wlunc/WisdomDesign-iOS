// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "WisdomDesign-iOS",
    platforms: [
        .iOS(.v17),
    ],
    products: [
        .library(name: "WisdomUI", targets: ["WisdomUI"]),
    ],
    targets: [
        .target(
            name: "WisdomUI",
            path: "Sources/WisdomUI"
        ),
        .testTarget(
            name: "WisdomUITests",
            dependencies: ["WisdomUI"],
            path: "Tests/WisdomUITests"
        ),
    ]
)
