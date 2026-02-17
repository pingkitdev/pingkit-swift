#if canImport(UIKit)
import UIKit
#endif
import Foundation

struct DeviceMetadata: Sendable {
    let deviceModel: String
    let osVersion: String
    let appVersion: String
    let appBuild: String
    let locale: String
    let timezone: String
}

enum MetadataCollector {
    @MainActor
    static func collect() -> DeviceMetadata {
        DeviceMetadata(
            deviceModel: machineIdentifier(),
            osVersion: osVersionString(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            appBuild: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown",
            locale: Locale.current.identifier,
            timezone: TimeZone.current.identifier
        )
    }

    private static func machineIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machine = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingCString: $0)
            }
        }
        #if os(iOS)
        return machine ?? UIDevice.current.model
        #elseif os(macOS)
        return machine ?? "Mac"
        #endif
    }

    private static func osVersionString() -> String {
        #if os(iOS)
        return UIDevice.current.systemVersion
        #elseif os(macOS)
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
        #endif
    }
}
