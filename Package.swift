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
            path: "Example/AirDCExample/Source",
            exclude: ["AirDCExampleApp.swift", "BuildInfo/BuildInfoView.swift",
                      "Runtime/RuntimeStatusView.swift", "Runtime/ExampleRuntimeTerminationDelegate.swift"],
            sources: ["BuildInfo/BuildInfoSnapshot.swift", "Runtime/RuntimeAPI.swift",
                      "Runtime/RuntimeModel.swift", "Runtime/RuntimeTerminationCoordinator.swift"]
        ),
        .executableTarget(
            name: "AirDCExample",
            dependencies: ["AirDCObjC", "AirDCExampleModel"],
            path: "Example/AirDCExample/Source",
            exclude: ["BuildInfo/BuildInfoSnapshot.swift", "Runtime/RuntimeAPI.swift",
                      "Runtime/RuntimeModel.swift", "Runtime/RuntimeTerminationCoordinator.swift"],
            sources: ["AirDCExampleApp.swift", "BuildInfo/BuildInfoView.swift",
                      "Runtime/RuntimeStatusView.swift", "Runtime/ExampleRuntimeTerminationDelegate.swift"],
            linkerSettings: [
                .unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks"]),
            ]
        ),
        .testTarget(
            name: "AirDCObjCMetadataTests",
            dependencies: ["AirDCObjC"],
            path: "Test/AirDCObjC/Private",
            exclude: ["Runtime/ADCPrivateRuntimeTestBridge.h", "Runtime/ADCPrivateRuntimeTestBridge.m",
                      "Runtime/ADCRuntimeEventTests.swift", "Runtime/ADCSubscriptionTests.swift",
                      "Runtime/ADCRuntimeTests.swift"]
        ),
        .executableTarget(
            name: "AirDCRuntimeProbe",
            dependencies: ["AirDCObjC"],
            path: "Test/AirDCObjC/RuntimeProbe"
        ),
        .testTarget(
            name: "AirDCObjCRuntimeTests",
            dependencies: ["AirDCObjC"],
            path: "Test/AirDCObjC/Public",
            exclude: ["ADCBuildInfoTests.m"],
            sources: ["Runtime/ADCRuntimeTests.swift"]
        ),
        .testTarget(
            name: "AirDCExampleTests",
            dependencies: ["AirDCExampleModel"],
            path: "Example/AirDCExample/Test"
        ),
    ]
)
