// swift-tools-version: 5.9
import PackageDescription
let package = Package(
    name: "PulseShiftEnginePS",
    platforms: [.macOS(.v14)],
    products: [.library(name: "PulseShiftEnginePS", targets: ["PulseShiftEnginePS"])],
    targets: [
        .target(name: "PulseShiftEnginePS", path: "Pulse Shift", exclude: ["Assets.xcassets", "Audio", "Views", "ViewModels", "Services/GameCenterServicePS.swift", "DesignSystem", "Gameplay/Scene", "Pulse_ShiftApp.swift"], sources: ["Models", "Gameplay/Engine", "Services/PersistenceServicePS.swift", "Services/FeedbackServicePS.swift"], resources: [.process("Data")]),
        .testTarget(name: "PulseShiftTests", dependencies: ["PulseShiftEnginePS"], path: "Tests/PulseShiftTests")
    ]
)
