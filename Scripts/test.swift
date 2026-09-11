#!/usr/bin/env swift
// Select an installed iPhone simulator and run the regression suite.
import Foundation

struct SimulatorList: Decodable {
    struct Device: Decodable {
        let name: String
        let udid: String
        let isAvailable: Bool
    }
    let devices: [String: [Device]]
}

struct TestError: Error, CustomStringConvertible {
    let description: String
}

func run(_ arguments: [String], capture: Bool = false, root: URL) throws -> Data {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = arguments
    process.currentDirectoryURL = root
    let pipe = capture ? Pipe() : nil
    if let pipe = pipe { process.standardOutput = pipe }
    try process.run()
    let data = pipe?.fileHandleForReading.readDataToEndOfFile() ?? Data()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else {
        throw TestError(description: "\(arguments[0]) exited with status \(process.terminationStatus)")
    }
    return data
}

do {
    let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
    let environment = ProcessInfo.processInfo.environment
    var destination = environment["TEST_DESTINATION"] ?? ""
    if destination.isEmpty {
        let data = try run(["xcrun", "simctl", "list", "devices", "available", "-j"], capture: true, root: root)
        let list = try JSONDecoder().decode(SimulatorList.self, from: data)
        let runtimes = list.devices.keys.filter { $0.contains(".iOS-") }
            .sorted { $0.compare($1, options: .numeric) == .orderedDescending }
        let device = runtimes.lazy.compactMap { runtime in
            list.devices[runtime]?.first { $0.isAvailable && $0.name.hasPrefix("iPhone") }
        }.first
        guard let device = device else {
            throw TestError(description: "No available iPhone simulator. Install an iOS runtime in Xcode.")
        }
        destination = "platform=iOS Simulator,id=\(device.udid)"
    }
    _ = try run(["xcodebuild", "-project", "CryptViper.xcodeproj", "-scheme", "CryptViper",
                 "-destination", destination,
                 "-derivedDataPath", environment["DERIVED_DATA_PATH"] ?? "build/DerivedData",
                 "CODE_SIGNING_ALLOWED=NO", "test"], root: root)
} catch {
    FileHandle.standardError.write(Data("Tests failed: \(error)\n".utf8))
    exit(1)
}
