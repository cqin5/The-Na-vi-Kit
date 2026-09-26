// swift-tools-version: 6.0

import PackageDescription

/// Na'vi grammar: a lexicon generated from the LearnNavi dictionary data, a
/// generator that inflects words, and an analyser that takes inflected words apart.
/// Foundation only, so the app and the keyboard extension can both use it.
let package = Package(
    name: "NaviGrammar",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "NaviGrammar", targets: ["NaviGrammar"]),
    ],
    targets: [
        .target(
            name: "NaviGrammar",
            resources: [.copy("Resources/lexicon.tsv")]
        ),
        .testTarget(
            name: "NaviGrammarTests",
            dependencies: ["NaviGrammar"]
        ),
    ]
)
