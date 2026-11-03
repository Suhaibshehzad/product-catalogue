// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CatalogueCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "CatalogueCore", targets: ["CatalogueCore"]),
    ],
    targets: [
        .target(name: "CatalogueCore"),
        .testTarget(name: "CatalogueCoreTests", dependencies: ["CatalogueCore"]),
    ]
)
