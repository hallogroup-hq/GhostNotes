// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GhostNotes",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "GhostNotes", targets: ["GhostNotes"])
    ],
    targets: [
        .executableTarget(
            name: "GhostNotes",
            dependencies: [],
            path: "Sources/GhostNotes"
        )
    ]
)
