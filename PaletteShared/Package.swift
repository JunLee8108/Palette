// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "PaletteShared",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "PaletteShared", targets: ["PaletteShared"])
    ],
    targets: [
        .target(name: "PaletteShared")
    ]
)
