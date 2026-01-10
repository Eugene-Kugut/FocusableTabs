// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "FocusableTabs",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "FocusableTabs",
            targets: ["FocusableTabs"]
        )
    ],
    targets: [
        .target(
            name: "FocusableTabs",
            path: "Sources/FocusableTabs"
        )
    ]
)
