// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "AppFamilyFoundation",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(name: "AppFamilyDesign", targets: ["AppFamilyDesign"]),
        .library(name: "AppFamilyLocalizationQA", targets: ["AppFamilyLocalizationQA"])
    ],
    targets: [
        .target(name: "AppFamilyDesign"),
        .target(name: "AppFamilyLocalizationQA")
    ],
    swiftLanguageModes: [.v5]
)
