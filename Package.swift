// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LocalizeAR",
    platforms: [
        .macOS(.v10_15), .iOS(.v14)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "LocalizeAR",
            targets: ["LocalizeAR"]
        )
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "LocalizeAR",
            dependencies: [
                .target(name: "LocalizeAR_ObjC"),
                .target(name: "opencv2")
            ],
            path: "Sources/LocalizeAR"
        ),
        .target(
            name: "LocalizeAR_ObjC",
            dependencies: ["lar", "g2o", "opencv2"],
            path: "Sources/LocalizeAR-ObjC",
            cxxSettings: [
                // Include header only libraries
                .headerSearchPath("../External/Headers/"),
                .define("G2O_USE_VENDORED_CERES"),
                .unsafeFlags(["-std=c++17", "-Wno-incomplete-umbrella"])
            ],
            linkerSettings: [
                .linkedLibrary("c++"),
                .linkedFramework("Accelerate"),
                .linkedFramework("ARKit", .when(platforms: [.iOS])),
                .linkedFramework("OpenCL", .when(platforms: [.macOS]))
            ]
        ),
        // Uncoment below if working with local frameworks
//        .binaryTarget(name: "lar", path: "Frameworks/lar.xcframework"),
//        .binaryTarget(name: "g2o", path: "Frameworks/g2o.xcframework"),
//        .binaryTarget(name: "opencv2", path: "Frameworks/opencv2.xcframework"),
        
        // Recompute checksum via:
        // `swift package --package-path /path/to/package compute-checksum *.xcframework.zip`
        .binaryTarget(
            name: "lar",
            url: "https://github.com/kobejean/lar/releases/download/v0.6.0/lar.xcframework.zip",
            checksum: "4d74d00c508674d3368b65907847df07f5817e224574c32934b010a44d889aec"
        ),
        .binaryTarget(
            name: "g2o",
            url: "https://github.com/kobejean/lar/releases/download/v0.5.0/g2o.xcframework.zip",
            checksum: "9de68f2fbd6c70d7c55afbe9cd95256f0e88da94741c78c8326ce8e944b5c627"
        ),
        .binaryTarget(
            name: "opencv2",
            url: "https://github.com/kobejean/lar/releases/download/v0.5.0/opencv2.xcframework.zip",
            checksum: "5f2bf918896a317703ac39fa27fd4e6eb26e3dfc438e21ddf37458be59cbbf68"
        ),
        
//        .testTarget(
//            name: "LocalizeARTests",
//            dependencies: ["LocalizeAR"]
//        )
    ]
)
