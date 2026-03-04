// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Markviewz",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-cmark.git", from: "0.4.0"),
    ],
    targets: [
        .executableTarget(
            name: "Markviewz",
            dependencies: [
                .product(name: "cmark-gfm", package: "swift-cmark"),
                .product(name: "cmark-gfm-extensions", package: "swift-cmark"),
            ]
        ),
    ]
)
