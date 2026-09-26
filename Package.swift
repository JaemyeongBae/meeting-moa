// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "MoaMeeting", platforms: [.macOS(.v14)], products: [.executable(name: "MoaMeeting", targets: ["MoaMeeting"])], targets: [.executableTarget(name: "MoaMeeting")])
