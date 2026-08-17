// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "NFCTag",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "NFCTag", targets: ["NFCTag"])
    ],
    targets: [
        .target(name: "NFCTag", dependencies: [])
    ]
)
