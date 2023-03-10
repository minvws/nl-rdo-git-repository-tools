// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RepoTools",
	platforms: [
		.macOS(SupportedPlatform.MacOSVersion.v13),
	],
	products: [
		.executable(name: "repotools", targets: ["RepoTools"])
	],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/JohnSundell/ShellOut", from: "2.3.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
        .package(url: "https://github.com/Quick/Nimble", from: "11.2.1"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .executableTarget(
            name: "RepoTools",
            dependencies: [
                "RepoToolsCore",
                "ShellOut",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .target(
            name: "RepoToolsCore",
            dependencies: ["ShellOut"]
        ),
		.testTarget(name: "RepoToolsCoreTests", dependencies: ["RepoToolsCore", "Nimble"])
    ]
)
