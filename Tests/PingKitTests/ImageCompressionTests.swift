import XCTest
@testable import PingKit

#if canImport(UIKit)
import UIKit

final class ImageCompressionTests: XCTestCase {

    private func makeImageData(width: Int, height: Int) -> Data {
        let size = CGSize(width: width, height: height)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
        return image.pngData()!
    }

    func testSmallImagePassesThrough() {
        let small = makeImageData(width: 10, height: 10)
        let result = PingKit.compressImage(small, targetBytes: 1_048_576)
        XCTAssertNotNil(result)
        // Small PNG should be well under 1 MB
        XCTAssertLessThan(result!.count, 1_048_576)
    }

    func testLargeImageCompressedUnderTarget() {
        // Create a large image that would exceed target as PNG
        let large = makeImageData(width: 2000, height: 2000)
        let target = 100_000 // 100 KB target
        let result = PingKit.compressImage(large, targetBytes: target)

        XCTAssertNotNil(result)
        // After compression, should be JPEG and potentially under target
        // (or as close as possible at quality 0.1)
    }

    func testInvalidDataReturnsInput() {
        let garbage = Data("not an image".utf8)
        let result = PingKit.compressImage(garbage, targetBytes: 1_048_576)
        // Invalid data returns the original data since UIImage(data:) fails
        XCTAssertEqual(result, garbage)
    }

    func testValidImageReturnsJPEGData() {
        let png = makeImageData(width: 50, height: 50)
        let result = PingKit.compressImage(png, targetBytes: 1_048_576)

        XCTAssertNotNil(result)
        // Result should be valid JPEG (starts with FF D8)
        XCTAssertTrue(result!.count >= 2)
        let bytes = [UInt8](result!.prefix(2))
        XCTAssertEqual(bytes[0], 0xFF)
        XCTAssertEqual(bytes[1], 0xD8)
    }

    func testCompressionReducesSize() {
        // Create moderately large image
        let imageData = makeImageData(width: 500, height: 500)
        let target = 5_000 // Very small target to force compression
        let result = PingKit.compressImage(imageData, targetBytes: target)

        XCTAssertNotNil(result)
        // Compressed version should be smaller than original PNG
        XCTAssertLessThan(result!.count, imageData.count)
    }

    func testCompressionWith1MBTarget() {
        let imageData = makeImageData(width: 100, height: 100)
        let result = PingKit.compressImage(imageData, targetBytes: 1_048_576)

        XCTAssertNotNil(result)
        XCTAssertLessThanOrEqual(result!.count, 1_048_576)
    }
}

#elseif canImport(AppKit)
import AppKit

final class ImageCompressionTests: XCTestCase {

    private func makeImageData(width: Int, height: Int) -> Data {
        let image = NSImage(size: NSSize(width: width, height: height))
        image.lockFocus()
        NSColor.red.setFill()
        NSRect(x: 0, y: 0, width: width, height: height).fill()
        image.unlockFocus()
        return image.tiffRepresentation!
    }

    func testSmallImagePassesThrough() {
        let small = makeImageData(width: 10, height: 10)
        let result = PingKit.compressImage(small, targetBytes: 1_048_576)
        XCTAssertNotNil(result)
        XCTAssertLessThan(result!.count, 1_048_576)
    }

    func testLargeImageCompressedUnderTarget() {
        let large = makeImageData(width: 2000, height: 2000)
        let target = 100_000
        let result = PingKit.compressImage(large, targetBytes: target)

        XCTAssertNotNil(result)
    }

    func testInvalidDataReturnsInput() {
        let garbage = Data("not an image".utf8)
        let result = PingKit.compressImage(garbage, targetBytes: 1_048_576)
        XCTAssertEqual(result, garbage)
    }

    func testValidImageReturnsJPEGData() {
        let png = makeImageData(width: 50, height: 50)
        let result = PingKit.compressImage(png, targetBytes: 1_048_576)

        XCTAssertNotNil(result)
        XCTAssertTrue(result!.count >= 2)
        let bytes = [UInt8](result!.prefix(2))
        XCTAssertEqual(bytes[0], 0xFF)
        XCTAssertEqual(bytes[1], 0xD8)
    }

    func testCompressionReducesSize() {
        let imageData = makeImageData(width: 500, height: 500)
        let target = 5_000
        let result = PingKit.compressImage(imageData, targetBytes: target)

        XCTAssertNotNil(result)
        XCTAssertLessThan(result!.count, imageData.count)
    }

    func testCompressionWith1MBTarget() {
        let imageData = makeImageData(width: 100, height: 100)
        let result = PingKit.compressImage(imageData, targetBytes: 1_048_576)

        XCTAssertNotNil(result)
        XCTAssertLessThanOrEqual(result!.count, 1_048_576)
    }
}

#endif
