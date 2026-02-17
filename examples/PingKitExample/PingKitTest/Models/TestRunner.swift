import Foundation
import UIKit
import ImageIO
import PingKit

// MARK: - Data Models

enum TestStatus {
    case passed
    case failed
    case skipped
}

struct TestResult: Identifiable {
    let id = UUID()
    let name: String
    let category: String
    let status: TestStatus
    let duration: TimeInterval
    let detail: String
}

// MARK: - Test Runner

@MainActor
final class TestRunner: ObservableObject {
    @Published var results: [TestResult] = []
    @Published var isRunning = false
    @Published var currentTestName = ""
    @Published var completedCount = 0
    let totalTests = 23

    private var apiKey: String {
        UserDefaults.standard.string(forKey: "apiKey") ?? ""
    }

    private var options: PingKitOptions {
        let endpoint = UserDefaults.standard.string(forKey: "customEndpoint") ?? "https://app.pingkit.dev"
        let attest = UserDefaults.standard.object(forKey: "enableAppAttest") as? Bool ?? true
        let imageSize = UserDefaults.standard.object(forKey: "maxImageSizeMB") as? Double ?? 5.0
        return PingKitOptions(
            endpoint: endpoint,
            enableAppAttest: attest,
            maxImageSizeMB: imageSize
        )
    }

    private func configure() {
        PingKit.configure(apiKey: apiKey, options: options)
    }

    func runAll() async {
        results = []
        isRunning = true
        completedCount = 0

        let tests: [(String, String, () async -> TestResult)] = [
            // Configuration (3)
            ("Configure Basic", "Configuration", testConfigureBasic),
            ("Configure With Options", "Configuration", testConfigureWithOptions),
            ("Reconfigure Restores Defaults", "Configuration", testReconfigureDefaults),
            // Basic Submit (3)
            ("Submit Minimal", "Basic Submit", testSubmitMinimal),
            ("Submit All Fields", "Basic Submit", testSubmitAllFields),
            ("Submit Without Device Info", "Basic Submit", testSubmitWithoutDeviceInfo),
            // Submit Variations (5)
            ("Submit With Email", "Submit Variations", testSubmitWithEmail),
            ("Submit With Type", "Submit Variations", testSubmitWithType),
            ("Submit With Metadata", "Submit Variations", testSubmitWithMetadata),
            ("Submit With Image", "Submit Variations", testSubmitWithImage),
            ("Submit With Question Type", "Submit Variations", testSubmitWithQuestionType),
            ("EXIF Data Stripped", "Submit Variations", testExifDataStripped),
            // Validation (4)
            ("Empty Text (spaces)", "Validation", testEmptyTextSpaces),
            ("Text At 5000 Limit", "Validation", testTextAt5000Limit),
            ("Text Over 5000 Limit", "Validation", testTextOver5000Limit),
            ("Empty String", "Validation", testEmptyString),
            // Error Handling (4)
            ("Not Configured", "Error Handling", testNotConfigured),
            ("Unauthorized", "Error Handling", testUnauthorized),
            ("Key Restoration Verify", "Error Handling", testKeyRestorationVerify),
            ("Whitespace-Only Text", "Error Handling", testWhitespaceOnlyText),
            // Response Validation (3)
            ("Response ID Not Empty", "Response Validation", testResponseIdNotEmpty),
            ("Response Status Value", "Response Validation", testResponseStatusValue),
            ("Response Unique IDs", "Response Validation", testResponseUniqueIds),
        ]

        for (name, _, test) in tests {
            currentTestName = name
            let result = await test()
            results.append(result)
            completedCount += 1
        }

        currentTestName = ""
        isRunning = false
    }

    var passedCount: Int { results.filter { $0.status == .passed }.count }
    var failedCount: Int { results.filter { $0.status == .failed }.count }
    var skippedCount: Int { results.filter { $0.status == .skipped }.count }

    var groupedResults: [(String, [TestResult])] {
        let categories = ["Configuration", "Basic Submit", "Submit Variations", "Validation", "Error Handling", "Response Validation"]
        return categories.compactMap { cat in
            let items = results.filter { $0.category == cat }
            return items.isEmpty ? nil : (cat, items)
        }
    }

    // MARK: - Helpers

    private func uniqueText(_ testName: String) -> String {
        let short = UUID().uuidString.prefix(8)
        return "Automated test: \(testName) [\(short)]"
    }

    private func delay() async {
        try? await Task.sleep(nanoseconds: 500_000_000)
    }

    private func measure(_ block: () async throws -> String) async -> TestResult {
        // Placeholder — each test calls `run` directly
        fatalError()
    }

    private func run(
        name: String,
        category: String,
        skipDelay: Bool = false,
        block: () async throws -> String
    ) async -> TestResult {
        let start = CFAbsoluteTimeGetCurrent()
        do {
            let detail = try await block()
            let duration = CFAbsoluteTimeGetCurrent() - start
            if !skipDelay { await delay() }
            return TestResult(name: name, category: category, status: .passed, duration: duration, detail: detail)
        } catch {
            let duration = CFAbsoluteTimeGetCurrent() - start
            return TestResult(name: name, category: category, status: .failed, duration: duration, detail: "Error: \(error)")
        }
    }

    private func skip(name: String, category: String, reason: String) -> TestResult {
        TestResult(name: name, category: category, status: .skipped, duration: 0, detail: reason)
    }

    // MARK: - Configuration Tests

    private func testConfigureBasic() async -> TestResult {
        await run(name: "Configure Basic", category: "Configuration") {
            self.configure()
            guard let key = PingKit.apiKey, !key.isEmpty else {
                throw TestFailure("PingKit.apiKey is nil or empty after configure")
            }
            return "apiKey set to \(key.prefix(20))..."
        }
    }

    private func testConfigureWithOptions() async -> TestResult {
        await run(name: "Configure With Options", category: "Configuration") {
            PingKit.configure(apiKey: self.apiKey, options: self.options)
            guard PingKit.options.enableAppAttest == false else {
                throw TestFailure("enableAppAttest should be false")
            }
            guard PingKit.options.endpoint == self.options.endpoint else {
                throw TestFailure("endpoint should be \(self.options.endpoint)")
            }
            return "Options applied: enableAppAttest=false, endpoint=\(self.options.endpoint)"
        }
    }

    private func testReconfigureDefaults() async -> TestResult {
        await run(name: "Reconfigure Restores Defaults", category: "Configuration") {
            // Configure with non-default maxImageSizeMB
            let customOpts = PingKitOptions(
                endpoint: self.options.endpoint,
                enableAppAttest: false,
                maxImageSizeMB: 17
            )
            PingKit.configure(apiKey: self.apiKey, options: customOpts)
            guard PingKit.options.maxImageSizeMB == 17 else {
                throw TestFailure("maxImageSizeMB should be 17")
            }
            // Reconfigure with test defaults — should restore maxImageSizeMB
            self.configure()
            guard PingKit.options.maxImageSizeMB == self.options.maxImageSizeMB else {
                throw TestFailure("maxImageSizeMB should be \(self.options.maxImageSizeMB) after reconfigure, got \(PingKit.options.maxImageSizeMB)")
            }
            return "Defaults restored: maxImageSizeMB=\(PingKit.options.maxImageSizeMB)"
        }
    }

    // MARK: - Basic Submit Tests

    private func testSubmitMinimal() async -> TestResult {
        await run(name: "Submit Minimal", category: "Basic Submit") {
            self.configure()
            let result = try await PingKit.submit(text: self.uniqueText("Submit Minimal"))
            guard !result.id.isEmpty else {
                throw TestFailure("result.id is empty")
            }
            return "ID: \(result.id)"
        }
    }

    private func testSubmitAllFields() async -> TestResult {
        await run(name: "Submit All Fields", category: "Basic Submit") {
            self.configure()
            let result = try await PingKit.submit(
                text: self.uniqueText("Submit All Fields"),
                email: "test@example.com",
                type: "bug",
                metadata: ["screen": "test_runner", "source": "automated"]
            )
            guard !result.id.isEmpty else {
                throw TestFailure("result.id is empty")
            }
            return "ID: \(result.id)"
        }
    }

    private func testSubmitWithoutDeviceInfo() async -> TestResult {
        await run(name: "Submit Without Device Info", category: "Basic Submit") {
            self.configure()
            let result = try await PingKit.submit(
                text: self.uniqueText("Submit Without Device Info"),
                includeDeviceInfo: false
            )
            guard !result.id.isEmpty else {
                throw TestFailure("result.id is empty")
            }
            return "ID: \(result.id)"
        }
    }

    // MARK: - Submit Variations Tests

    private func testSubmitWithEmail() async -> TestResult {
        await run(name: "Submit With Email", category: "Submit Variations") {
            self.configure()
            let result = try await PingKit.submit(
                text: self.uniqueText("Submit With Email"),
                email: "user@test.com"
            )
            guard !result.id.isEmpty else {
                throw TestFailure("result.id is empty")
            }
            return "ID: \(result.id)"
        }
    }

    private func testSubmitWithType() async -> TestResult {
        await run(name: "Submit With Type", category: "Submit Variations") {
            self.configure()
            let result = try await PingKit.submit(
                text: self.uniqueText("Submit With Type"),
                type: "feature"
            )
            guard !result.id.isEmpty else {
                throw TestFailure("result.id is empty")
            }
            return "ID: \(result.id)"
        }
    }

    private func testSubmitWithMetadata() async -> TestResult {
        await run(name: "Submit With Metadata", category: "Submit Variations") {
            self.configure()
            let result = try await PingKit.submit(
                text: self.uniqueText("Submit With Metadata"),
                metadata: ["screen": "test_runner"]
            )
            guard !result.id.isEmpty else {
                throw TestFailure("result.id is empty")
            }
            return "ID: \(result.id)"
        }
    }

    private func testSubmitWithImage() async -> TestResult {
        await run(name: "Submit With Image", category: "Submit Variations") {
            self.configure()
            // Create a 2x2 red image
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2))
            let imageData = renderer.jpegData(withCompressionQuality: 0.8) { ctx in
                UIColor.red.setFill()
                ctx.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
            }
            let result = try await PingKit.submit(
                text: self.uniqueText("Submit With Image"),
                image: imageData
            )
            guard !result.id.isEmpty else {
                throw TestFailure("result.id is empty")
            }
            return "ID: \(result.id), image=\(imageData.count) bytes"
        }
    }

    private func testSubmitWithQuestionType() async -> TestResult {
        await run(name: "Submit With Question Type", category: "Submit Variations") {
            self.configure()
            let result = try await PingKit.submit(
                text: self.uniqueText("Submit With Question Type"),
                type: "question"
            )
            guard !result.id.isEmpty else {
                throw TestFailure("result.id is empty")
            }
            return "ID: \(result.id)"
        }
    }

    private func testExifDataStripped() async -> TestResult {
        await run(name: "EXIF Data Stripped", category: "Submit Variations", skipDelay: true) {
            // Create a 10x10 image with EXIF GPS metadata baked into the JPEG data
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10))
            let rawJpeg = renderer.jpegData(withCompressionQuality: 0.9) { ctx in
                UIColor.blue.setFill()
                ctx.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
            }

            // Embed EXIF metadata using ImageIO
            guard let source = CGImageSourceCreateWithData(rawJpeg as CFData, nil),
                  let uti = CGImageSourceGetType(source) else {
                throw TestFailure("Failed to create image source")
            }
            let exif: [String: Any] = [
                kCGImagePropertyExifUserComment as String: "secret_exif_marker",
                kCGImagePropertyExifDateTimeOriginal as String: "2025:01:01 12:00:00",
            ]
            let gps: [String: Any] = [
                kCGImagePropertyGPSLatitude as String: 37.7749,
                kCGImagePropertyGPSLatitudeRef as String: "N",
                kCGImagePropertyGPSLongitude as String: 122.4194,
                kCGImagePropertyGPSLongitudeRef as String: "W",
            ]
            let metadata: [String: Any] = [
                kCGImagePropertyExifDictionary as String: exif,
                kCGImagePropertyGPSDictionary as String: gps,
            ]
            let mutableData = NSMutableData()
            guard let dest = CGImageDestinationCreateWithData(mutableData, uti, 1, nil) else {
                throw TestFailure("Failed to create image destination")
            }
            CGImageDestinationAddImageFromSource(dest, source, 0, metadata as CFDictionary)
            guard CGImageDestinationFinalize(dest) else {
                throw TestFailure("Failed to finalize image with EXIF")
            }
            let exifJpeg = mutableData as Data

            // Verify the EXIF data is actually present in the source
            guard let srcWithExif = CGImageSourceCreateWithData(exifJpeg as CFData, nil),
                  let props = CGImageSourceCopyPropertiesAtIndex(srcWithExif, 0, nil) as? [String: Any],
                  props[kCGImagePropertyGPSDictionary as String] != nil else {
                throw TestFailure("GPS EXIF not embedded in source image")
            }

            // Simulate the SDK's compression pipeline: UIImage(data:) → jpegData()
            guard let uiImage = UIImage(data: exifJpeg),
                  let processed = uiImage.jpegData(compressionQuality: 0.8) else {
                throw TestFailure("Failed to roundtrip image through UIImage")
            }

            // Verify EXIF is stripped from the processed output
            guard let processedSource = CGImageSourceCreateWithData(processed as CFData, nil),
                  let processedProps = CGImageSourceCopyPropertiesAtIndex(processedSource, 0, nil) as? [String: Any] else {
                throw TestFailure("Failed to read processed image properties")
            }
            let hasGPS = processedProps[kCGImagePropertyGPSDictionary as String] != nil
            let hasExif = (processedProps[kCGImagePropertyExifDictionary as String] as? [String: Any])?["UserComment"] != nil

            if hasGPS {
                throw TestFailure("GPS data survived UIImage roundtrip — EXIF not stripped")
            }
            if hasExif {
                throw TestFailure("EXIF UserComment survived UIImage roundtrip — EXIF not stripped")
            }

            return "EXIF stripped: GPS=removed, UserComment=removed (source=\(exifJpeg.count)B → processed=\(processed.count)B)"
        }
    }

    // MARK: - Validation Tests

    private func testEmptyTextSpaces() async -> TestResult {
        await run(name: "Empty Text (spaces)", category: "Validation", skipDelay: true) {
            self.configure()
            do {
                _ = try await PingKit.submit(text: "   ")
                throw TestFailure("Should have thrown invalidInput for spaces-only text")
            } catch is TestFailure {
                throw TestFailure("Should have thrown invalidInput for spaces-only text")
            } catch let error as PingKitError {
                if case .invalidInput = error {
                    return "Correctly threw PingKitError.invalidInput"
                }
                throw TestFailure("Expected invalidInput, got \(error)")
            }
        }
    }

    private func testTextAt5000Limit() async -> TestResult {
        await run(name: "Text At 5000 Limit", category: "Validation") {
            self.configure()
            let longText = String(repeating: "a", count: 4950) + " " + self.uniqueText("5000Limit")
            // Trim to exactly 5000
            let text = String(longText.prefix(5000))
            let result = try await PingKit.submit(text: text)
            guard !result.id.isEmpty else {
                throw TestFailure("result.id is empty")
            }
            return "ID: \(result.id), text length=\(text.count)"
        }
    }

    private func testTextOver5000Limit() async -> TestResult {
        await run(name: "Text Over 5000 Limit", category: "Validation", skipDelay: true) {
            self.configure()
            let text = String(repeating: "a", count: 5001)
            do {
                _ = try await PingKit.submit(text: text)
                throw TestFailure("Should have thrown invalidInput for text over 5000 chars")
            } catch is TestFailure {
                throw TestFailure("Should have thrown invalidInput for text over 5000 chars")
            } catch let error as PingKitError {
                if case .invalidInput = error {
                    return "Correctly threw PingKitError.invalidInput for \(text.count) chars"
                }
                throw TestFailure("Expected invalidInput, got \(error)")
            }
        }
    }

    private func testEmptyString() async -> TestResult {
        await run(name: "Empty String", category: "Validation", skipDelay: true) {
            self.configure()
            do {
                _ = try await PingKit.submit(text: "")
                throw TestFailure("Should have thrown invalidInput for empty string")
            } catch is TestFailure {
                throw TestFailure("Should have thrown invalidInput for empty string")
            } catch let error as PingKitError {
                if case .invalidInput = error {
                    return "Correctly threw PingKitError.invalidInput"
                }
                throw TestFailure("Expected invalidInput, got \(error)")
            }
        }
    }

    // MARK: - Error Handling Tests

    private func testNotConfigured() async -> TestResult {
        skip(name: "Not Configured", category: "Error Handling", reason: "No public reset API after configure()")
    }

    private func testUnauthorized() async -> TestResult {
        await run(name: "Unauthorized", category: "Error Handling") {
            defer { self.configure() }
            PingKit.configure(apiKey: "pk_proj_INVALID_KEY_12345", options: self.options)
            do {
                _ = try await PingKit.submit(text: self.uniqueText("Unauthorized"))
                throw TestFailure("Should have thrown unauthorized for bad key")
            } catch is TestFailure {
                throw TestFailure("Should have thrown unauthorized for bad key")
            } catch PingKitError.unauthorized {
                return "Correctly threw PingKitError.unauthorized"
            }
        }
    }

    private func testKeyRestorationVerify() async -> TestResult {
        await run(name: "Key Restoration Verify", category: "Error Handling") {
            self.configure()
            let result = try await PingKit.submit(text: self.uniqueText("Key Restoration Verify"))
            guard !result.id.isEmpty else {
                throw TestFailure("result.id is empty — key may not have been restored")
            }
            return "ID: \(result.id) — key correctly restored"
        }
    }

    private func testWhitespaceOnlyText() async -> TestResult {
        await run(name: "Whitespace-Only Text", category: "Error Handling", skipDelay: true) {
            self.configure()
            do {
                _ = try await PingKit.submit(text: "\t\n  \t")
                throw TestFailure("Should have thrown invalidInput for whitespace-only text")
            } catch is TestFailure {
                throw TestFailure("Should have thrown invalidInput for whitespace-only text")
            } catch let error as PingKitError {
                if case .invalidInput = error {
                    return "Correctly threw PingKitError.invalidInput"
                }
                throw TestFailure("Expected invalidInput, got \(error)")
            }
        }
    }

    // MARK: - Response Validation Tests

    private func testResponseIdNotEmpty() async -> TestResult {
        await run(name: "Response ID Not Empty", category: "Response Validation") {
            self.configure()
            let result = try await PingKit.submit(text: self.uniqueText("Response ID Not Empty"))
            guard !result.id.isEmpty else {
                throw TestFailure("result.id is empty")
            }
            return "ID: \(result.id)"
        }
    }

    private func testResponseStatusValue() async -> TestResult {
        await run(name: "Response Status Value", category: "Response Validation") {
            self.configure()
            let result = try await PingKit.submit(text: self.uniqueText("Response Status Value"))
            guard result.status == "new" else {
                throw TestFailure("Expected status 'new', got '\(result.status)'")
            }
            return "status=\(result.status)"
        }
    }

    private func testResponseUniqueIds() async -> TestResult {
        await run(name: "Response Unique IDs", category: "Response Validation") {
            self.configure()
            let result1 = try await PingKit.submit(text: self.uniqueText("Unique IDs 1"))
            await self.delay()
            let result2 = try await PingKit.submit(text: self.uniqueText("Unique IDs 2"))
            guard result1.id != result2.id else {
                throw TestFailure("Two submissions returned the same ID: \(result1.id)")
            }
            return "ID1: \(result1.id), ID2: \(result2.id)"
        }
    }
}

// MARK: - Test Failure

private struct TestFailure: Error, CustomStringConvertible {
    let message: String
    var description: String { message }
    init(_ message: String) { self.message = message }
}
