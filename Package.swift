// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "BarikEnhanced",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Barik", targets: ["BarikEnhanced"]),
    ],
    dependencies: [
        .package(url: "https://github.com/dduan/TOMLDecoder", exact: "0.3.1"),
        .package(url: "https://github.com/gonzalezreal/swift-markdown-ui", exact: "2.4.1"),
    ],
    targets: [
        .executableTarget(
            name: "BarikEnhanced",
            dependencies: [
                "TOMLDecoder",
                .product(name: "MarkdownUI", package: "swift-markdown-ui"),
            ],
            path: ".",
            exclude: [
                "BarikEnhancedTests", "resources", "example", "scripts",
                "README.md", "CHANGELOG.md", "CLAUDE.md", "LICENSE",
                "BarikEnhanced/Info.plist",
                "BarikEnhanced/BarikEnhanced.entitlements",
                "BarikEnhanced/Resources",
            ],
            sources: ["BarikEnhanced", "SwiftPM"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "BarikEnhancedTests",
            dependencies: ["BarikEnhanced"],
            path: "BarikEnhancedTests"
        ),
    ]
)
