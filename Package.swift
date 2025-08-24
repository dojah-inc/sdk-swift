// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DojahWidget",
    platforms: [.iOS(.v14)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(name: "DojahWidget", targets: ["DojahWidget"]),
    ],
    dependencies: [
        .package(url: "https://github.com/airbnb/HorizonCalendar.git", from: "1.0.0"),
        .package(url: "https://github.com/airbnb/lottie-ios.git", from: "4.5.2"),
        .package(url: "https://github.com/realm/realm-swift.git", from: "10.52.2"),
        .package(url: "https://github.com/hackiftekhar/IQKeyboardManager.git", from: "6.5.0"),
        .package(url: "https://github.com/googlemaps/ios-places-sdk", from: "8.3.0"),
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "DojahWidget",
            dependencies: [
                "HorizonCalendar",
                .product(name: "Lottie", package: "lottie-ios"),
                //.product(name: "Realm", package: "realm-swift"),
                .product(name: "RealmSwift", package: "realm-swift"),
                .product(name: "IQKeyboardManagerSwift", package: "IQKeyboardManager"),
                .product(name: "Kingfisher", package: "Kingfisher"),
                .product(name: "GooglePlaces", package: "ios-places-sdk")
            ],
            resources: [
                .process("Resources")  // <- includes JSON,
            ]
        ),
        .testTarget(name: "DojahWidgetTests", dependencies: ["DojahWidget"]),
    ]
)
