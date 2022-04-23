// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "ASATools",
    platforms: [
        .iOS(.v9)
    ],
    products: [.library(name: "ASATools", targets: ["ASATools"])],
    targets: [.target(name: "ASATools", path: "ASATools")],
    swiftLanguageVersions: [.v5]
)
