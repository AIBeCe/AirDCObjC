// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AirDCObjC",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "AirDCObjC", targets: ["AirDCObjC"]),
        .executable(name: "AirDCExample", targets: ["AirDCExample"]),
    ],
    targets: [
        .binaryTarget(name: "AirDCObjC", path: "Dist/AirDCObjC.xcframework"),
        .target(
            name: "AirDCExampleModel",
            dependencies: ["AirDCObjC"],
            path: "Example/AirDCExample/Source/BuildInfo",
            exclude: ["BuildInfoView.swift"],
            sources: ["BuildInfoSnapshot.swift"]
        ),
        .executableTarget(
            name: "AirDCExample",
            dependencies: ["AirDCObjC", "AirDCExampleModel"],
            path: "Example/AirDCExample/Source",
            exclude: ["BuildInfo/BuildInfoSnapshot.swift"],
            sources: ["AirDCExampleApp.swift", "BuildInfo/BuildInfoView.swift"],
            linkerSettings: [
                .unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks"]),
            ]
        ),
        .testTarget(
            name: "AirDCObjCMetadataTests",
            dependencies: ["AirDCObjC"],
            path: "Test/AirDCObjC/Private"
        ),
        .testTarget(
            name: "AirDCExampleTests",
            dependencies: ["AirDCExampleModel"],
            path: "Example/AirDCExample/Test/BuildInfo"
        ),
    ]
)
