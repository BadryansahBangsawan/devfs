// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DevFS",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "DevFS", targets: ["DevFS"])
    ],
    targets: [
        .executableTarget(name: "DevFS", path: "Sources")
    ]
)
