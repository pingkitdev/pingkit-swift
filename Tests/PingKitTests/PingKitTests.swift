import ImageIO
import XCTest
@testable import PingKit

final class PingKitTests: XCTestCase {
    override func tearDown() {
        super.tearDown()
        // Reset state between tests
        PingKit.apiKey = nil
    }

    func testConfigureSetsApiKey() {
        PingKit.configure(apiKey: "pk_proj_testkey123")
        XCTAssertEqual(PingKit.apiKey, "pk_proj_testkey123")
    }

    func testConfigureSetsOptions() {
        let options = PingKitOptions(
            endpoint: "https://custom.example.com",
            enableAppAttest: false,
            maxImageSizeMB: 3
        )
        PingKit.configure(apiKey: "pk_proj_test", options: options)
        XCTAssertEqual(PingKit.options.endpoint, "https://custom.example.com")
        XCTAssertFalse(PingKit.options.enableAppAttest)
        XCTAssertEqual(PingKit.options.maxImageSizeMB, 3)
    }

    func testConfigureSetsDefaultOptions() {
        PingKit.configure(apiKey: "pk_proj_test")
        XCTAssertEqual(PingKit.options.endpoint, "https://app.pingkit.dev")
        XCTAssertTrue(PingKit.options.enableAppAttest)
        XCTAssertEqual(PingKit.options.maxImageSizeMB, 5)
    }

    func testSubmitWithoutConfigureThrows() async {
        do {
            try await PingKit.submit(text: "test")
            XCTFail("Expected PingKitError.notConfigured")
        } catch let error as PingKitError {
            if case .notConfigured = error {
                // Expected
            } else {
                XCTFail("Expected .notConfigured, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSubmitRejectsEmptyText() async {
        PingKit.configure(apiKey: "pk_proj_test")
        do {
            try await PingKit.submit(text: "")
            XCTFail("Expected PingKitError.invalidInput")
        } catch let error as PingKitError {
            if case .invalidInput = error {
                // Expected
            } else {
                XCTFail("Expected .invalidInput, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSubmitRejectsWhitespaceOnlyText() async {
        PingKit.configure(apiKey: "pk_proj_test")
        do {
            try await PingKit.submit(text: "   \n\t  ")
            XCTFail("Expected PingKitError.invalidInput")
        } catch let error as PingKitError {
            if case .invalidInput = error {
                // Expected
            } else {
                XCTFail("Expected .invalidInput, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - EXIF Metadata Stripping

    /// Helper: create a 1x1 JPEG with GPS metadata baked in via ImageIO.
    private func makeJPEGWithGPS() -> Data {
        let width = 1, height = 1
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let ctx = CGContext(
            data: nil, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: 4 * width,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        ctx.setFillColor(red: 1, green: 0, blue: 0, alpha: 1)
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        let cgImage = ctx.makeImage()!

        let mutableData = NSMutableData()
        let dest = CGImageDestinationCreateWithData(mutableData, "public.jpeg" as CFString, 1, nil)!

        let properties: [CFString: Any] = [
            kCGImagePropertyGPSDictionary: [
                kCGImagePropertyGPSLatitude: 37.7749,
                kCGImagePropertyGPSLatitudeRef: "N",
                kCGImagePropertyGPSLongitude: 122.4194,
                kCGImagePropertyGPSLongitudeRef: "W",
            ],
            kCGImagePropertyExifDictionary: [
                kCGImagePropertyExifLensMake: "TestLens",
            ],
        ]
        CGImageDestinationAddImage(dest, cgImage, properties as CFDictionary)
        CGImageDestinationFinalize(dest)

        return mutableData as Data
    }

    func testStripImageMetadataRemovesGPS() {
        let original = makeJPEGWithGPS()

        // Verify GPS is present in the original
        let originalSource = CGImageSourceCreateWithData(original as CFData, nil)!
        let originalProps = CGImageSourceCopyPropertiesAtIndex(originalSource, 0, nil) as? [CFString: Any]
        XCTAssertNotNil(originalProps?[kCGImagePropertyGPSDictionary], "Test image should have GPS data")

        // Strip and verify GPS + EXIF are gone
        let stripped = PingKit.stripImageMetadata(original)
        let strippedSource = CGImageSourceCreateWithData(stripped as CFData, nil)!
        let strippedProps = CGImageSourceCopyPropertiesAtIndex(strippedSource, 0, nil) as? [CFString: Any]
        XCTAssertNil(strippedProps?[kCGImagePropertyGPSDictionary], "GPS metadata should be removed")

        // ImageIO may regenerate a minimal EXIF dict with structural keys (ColorSpace, PixelXDimension).
        // Verify the user-supplied sensitive key (LensMake) was removed.
        let exif = strippedProps?[kCGImagePropertyExifDictionary] as? [CFString: Any]
        XCTAssertNil(exif?[kCGImagePropertyExifLensMake], "Sensitive EXIF keys should be removed")
    }

    func testStripImageMetadataPreservesImageContent() {
        let original = makeJPEGWithGPS()
        let stripped = PingKit.stripImageMetadata(original)

        // Stripped data should still be a valid image
        let source = CGImageSourceCreateWithData(stripped as CFData, nil)
        XCTAssertNotNil(source, "Stripped data should be a valid image source")

        let cgImage = CGImageSourceCreateImageAtIndex(source!, 0, nil)
        XCTAssertNotNil(cgImage, "Stripped data should produce a valid CGImage")
        XCTAssertEqual(cgImage?.width, 1)
        XCTAssertEqual(cgImage?.height, 1)
    }

    func testStripImageMetadataHandlesInvalidData() {
        let garbage = Data([0xDE, 0xAD, 0xBE, 0xEF])
        let result = PingKit.stripImageMetadata(garbage)
        XCTAssertEqual(result, garbage, "Invalid data should be returned as-is")
    }

    func testSubmitRejectsOverlongText() async {
        PingKit.configure(apiKey: "pk_proj_test")
        let longText = String(repeating: "a", count: 5001)
        do {
            try await PingKit.submit(text: longText)
            XCTFail("Expected PingKitError.invalidInput")
        } catch let error as PingKitError {
            if case .invalidInput = error {
                // Expected
            } else {
                XCTFail("Expected .invalidInput, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
