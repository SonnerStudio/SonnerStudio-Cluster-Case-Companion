// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SSCCCApp",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "SSCCCApp", targets: ["SSCCCApp"])
    ],
    targets: [
        .executableTarget(
            name: "SSCCCApp",
            path: "Sources",
            exclude: [
                "Models/.gitkeep",
                "Services/.gitkeep",
                "ViewModels/.gitkeep",
                "Views/.gitkeep"
            ]
        )
    ]
)
