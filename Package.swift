// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacMouse",
    platforms: [.macOS("27.0")],
    products: [.library(name: "MacMouseCore", targets: ["MacMouseCore"]),
               .executable(name: "MacMouse", targets: ["MacMouse"])],
    targets: [
        .target(name: "MacMouseCore"),
        .executableTarget(name: "MacMouse", dependencies: ["MacMouseCore"], exclude: ["Resources"])
    ]
)
