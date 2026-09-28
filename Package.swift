// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Aether",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Aether", targets: ["Aether"])
    ],
    targets: [
        .executableTarget(
            name: "Aether",
            path: "Sources/MacClean"
        )
    ]
)
