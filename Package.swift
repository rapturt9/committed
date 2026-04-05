// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Committed",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Committed",
            path: "Committed/Sources",
            swiftSettings: [
                .unsafeFlags(["-parse-as-library"]),
                .unsafeFlags(["-strict-concurrency=minimal"])
            ],
            linkerSettings: [
                .linkedFramework("SwiftUI"),
                .linkedFramework("AppKit"),
                .linkedFramework("EventKit"),
                .linkedFramework("ServiceManagement"),
                .linkedFramework("UserNotifications")
            ]
        ),
        .testTarget(
            name: "CommittedTests",
            dependencies: ["Committed"],
            path: "Tests",
            swiftSettings: [
                .unsafeFlags(["-strict-concurrency=minimal"])
            ]
        )
    ]
)
