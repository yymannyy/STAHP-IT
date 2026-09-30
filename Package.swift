// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "StahpIt",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "StahpIt",
            targets: ["StahpIt"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "StahpIt",
            dependencies: [],
            path: "Sources"
        )
    ]
)
