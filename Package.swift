// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Glint",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "Glint",
            dependencies: []
        )
    ]
)
