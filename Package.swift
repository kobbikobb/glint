// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Glint",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/hmlongco/Factory", from: "2.4.0"),
    ],
    targets: [
        .executableTarget(
            name: "Glint",
            dependencies: [
                .product(name: "Factory", package: "Factory"),
            ]
        ),
        .testTarget(
            name: "GlintTests",
            dependencies: ["Glint"]
        )
    ]
)
