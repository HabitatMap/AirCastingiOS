// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AirCastingStyling",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "AirCastingStyling",
            targets: ["AirCastingStyling"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "AirCastingStyling",
            dependencies: []),
        .testTarget(
            name: "AirCastingStylingTests",
            dependencies: ["AirCastingStyling"]),
    ]
)
