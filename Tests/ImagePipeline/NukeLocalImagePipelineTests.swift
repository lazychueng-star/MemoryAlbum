import ImageIO
import Nuke
import UniformTypeIdentifiers
import UIKit
import XCTest
@testable import MemoryAlbum

final class NukeLocalImagePipelineTests: XCTestCase {
    func testNukeLocalImageGate() async throws {
        let fixtures = try NukeImageGateFixtures()
        defer { fixtures.remove() }

        let loader = NukeLocalImagePipeline(memoryCostLimit: 64 * 1_024 * 1_024)
        let heicGalleryStart = Date()
        let heicFileLoad = await loader.loadFile(
            at: fixtures.heicURL,
            variant: .gallery
        )
        let heicGallery = try await heicFileLoad.image
        let heicGalleryMilliseconds = elapsedMilliseconds(since: heicGalleryStart)
        let gallerySize = try pixelSize(of: heicGallery)
        XCTAssertLessThanOrEqual(max(gallerySize.width, gallerySize.height), 1_000)

        let heicThumbnail = try await loader.loadFile(
            at: fixtures.heicURL,
            variant: .thumbnail
        ).image
        let thumbnailSize = try pixelSize(of: heicThumbnail)
        XCTAssertLessThanOrEqual(max(thumbnailSize.width, thumbnailSize.height), 320)

        let heicDataLoad = await loader.loadData(
            fixtures.heicData,
            id: "forty-eight-megapixel-heic",
            variant: .gallery
        )
        let heicDataImage = try await heicDataLoad.image
        let dataImageSize = try pixelSize(of: heicDataImage)
        XCTAssertLessThanOrEqual(max(dataImageSize.width, dataImageSize.height), 1_000)

        let jpegStart = Date()
        for fixture in fixtures.jpegFixtures {
            let image = try await loader.loadFile(
                at: fixture.url,
                variant: .thumbnail
            ).image
            let size = try pixelSize(of: image)
            XCTAssertLessThanOrEqual(max(size.width, size.height), 320)
            XCTAssertTrue(fixture.isTwelveMegapixel)
        }
        let jpegMilliseconds = elapsedMilliseconds(since: jpegStart)

        let orientedImage = try await loader.loadFile(
            at: fixtures.orientedJPEGURL,
            variant: .gallery
        ).image
        let orientedSize = try pixelSize(of: orientedImage)
        XCTAssertLessThanOrEqual(max(orientedSize.width, orientedSize.height), 1_000)
        XCTAssertGreaterThan(orientedSize.height, orientedSize.width)

        let cancellationStart = Date()
        var supersededLoads: [LocalImageLoad] = []
        var currentLoad = await loader.loadFile(
            at: fixtures.rapidURLs[0],
            variant: .gallery
        )
        for url in fixtures.rapidURLs.dropFirst() {
            let nextLoad = await loader.loadFile(at: url, variant: .gallery)
            currentLoad.cancel()
            supersededLoads.append(currentLoad)
            currentLoad = nextLoad
        }

        let finalRapidImage = try await currentLoad.image
        let finalRapidSize = try pixelSize(of: finalRapidImage)
        XCTAssertLessThanOrEqual(max(finalRapidSize.width, finalRapidSize.height), 1_000)

        var cancelledCount = 0
        for load in supersededLoads {
            do {
                _ = try await load.image
                XCTFail("A superseded local image request completed instead of being cancelled")
            } catch ImagePipeline.Error.cancelled {
                cancelledCount += 1
            } catch {
                XCTFail("Unexpected cancellation error: \(error)")
            }
        }
        XCTAssertEqual(cancelledCount, 49)
        let cancellationMilliseconds = elapsedMilliseconds(since: cancellationStart)

        let cacheBeforeRelease = await loader.memoryCacheSnapshot()
        XCTAssertGreaterThan(cacheBeforeRelease.count, 0)
        XCTAssertGreaterThan(cacheBeforeRelease.costBytes, 0)

        let weakImage = try await makeWeakGalleryImage(
            with: loader,
            url: fixtures.cacheProofURL
        )
        await loader.removeAllMemoryCache()
        try await Task.sleep(for: .milliseconds(100))

        let cacheAfterRelease = await loader.memoryCacheSnapshot()
        XCTAssertEqual(cacheAfterRelease.count, 0)
        XCTAssertEqual(cacheAfterRelease.costBytes, 0)
        XCTAssertNil(weakImage.image)

        let gateEvidence =
            "NUKE_GATE heic_48mp_gallery_ms=\(heicGalleryMilliseconds) "
                + "heic_48mp_gallery_px=\(gallerySize.width)x\(gallerySize.height) "
                + "heic_48mp_thumbnail_px=\(thumbnailSize.width)x\(thumbnailSize.height) "
                + "heic_48mp_data_px=\(dataImageSize.width)x\(dataImageSize.height) "
                + "jpeg_12mp_count=10 jpeg_12mp_thumbnails_ms=\(jpegMilliseconds) "
                + "exif_orientation=6 transformed_px=\(orientedSize.width)x\(orientedSize.height) "
                + "rapid_updates=50 cancelled=\(cancelledCount) update_cycle_ms=\(cancellationMilliseconds) "
                + "cache_before_release_count=\(cacheBeforeRelease.count) "
                + "cache_before_release_bytes=\(cacheBeforeRelease.costBytes) "
                + "cache_after_release_count=\(cacheAfterRelease.count)"
        let attachment = XCTAttachment(
            data: Data(gateEvidence.utf8),
            uniformTypeIdentifier: UTType.plainText.identifier
        )
        attachment.name = "NUKE_GATE"
        attachment.lifetime = .keepAlways
        add(attachment)
        print(gateEvidence)
    }

    private func makeWeakGalleryImage(
        with loader: NukeLocalImagePipeline,
        url: URL
    ) async throws -> WeakImage {
        let image = try await loader.loadFile(
            at: url,
            variant: .gallery
        ).image
        return WeakImage(image: image)
    }

    private func pixelSize(of image: UIImage) throws -> (width: Int, height: Int) {
        let cgImage = try XCTUnwrap(image.cgImage)
        return (cgImage.width, cgImage.height)
    }

    private func elapsedMilliseconds(since start: Date) -> Int {
        Int(Date().timeIntervalSince(start) * 1_000)
    }
}

private final class WeakImage {
    weak var image: UIImage?

    init(image: UIImage) {
        self.image = image
    }
}

private struct JPEGFixture: Sendable {
    let url: URL
    let isTwelveMegapixel: Bool
}

private struct NukeImageGateFixtures {
    let directory: URL
    let heicURL: URL
    let heicData: Data
    let jpegFixtures: [JPEGFixture]
    let orientedJPEGURL: URL
    let cacheProofURL: URL
    let rapidURLs: [URL]

    init() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("NukeImageGate-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        self.directory = directory

        heicURL = directory.appendingPathComponent("forty-eight-megapixel.heic")
        try ImageFixtureWriter.write(
            width: 8_000,
            height: 6_000,
            type: .heic,
            to: heicURL
        )
        heicData = try Data(contentsOf: heicURL)

        jpegFixtures = try (0..<10).map { index in
            let url = directory.appendingPathComponent("twelve-megapixel-\(index).jpg")
            try ImageFixtureWriter.write(
                width: 4_000,
                height: 3_000,
                type: .jpeg,
                to: url
            )
            return JPEGFixture(url: url, isTwelveMegapixel: true)
        }

        orientedJPEGURL = directory.appendingPathComponent("orientation-six.jpg")
        try ImageFixtureWriter.write(
            width: 4_000,
            height: 3_000,
            type: .jpeg,
            orientation: 6,
            to: orientedJPEGURL
        )
        XCTAssertEqual(try ImageFixtureWriter.orientation(of: orientedJPEGURL), 6)

        cacheProofURL = directory.appendingPathComponent("cache-proof.jpg")
        try FileManager.default.copyItem(at: jpegFixtures[0].url, to: cacheProofURL)

        let sourceURL = heicURL
        var rapidURLs: [URL] = []
        for index in 0..<50 {
            let url = directory.appendingPathComponent("rapid-\(index).heic")
            try FileManager.default.linkItem(at: sourceURL, to: url)
            rapidURLs.append(url)
        }
        self.rapidURLs = rapidURLs
    }

    func remove() {
        try? FileManager.default.removeItem(at: directory)
    }
}

private enum ImageFixtureWriter {
    static func write(
        width: Int,
        height: Int,
        type: UTType,
        orientation: Int? = nil,
        to url: URL
    ) throws {
        let image = try makeImage(width: width, height: height)
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            type.identifier as CFString,
            1,
            nil
        ) else {
            throw FixtureError.destinationUnavailable(type.identifier)
        }

        var properties: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: 0.6
        ]
        if let orientation {
            properties[kCGImagePropertyOrientation] = orientation
        }
        CGImageDestinationAddImage(destination, image, properties as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            throw FixtureError.encodingFailed(url.lastPathComponent)
        }
    }

    static func orientation(of url: URL) throws -> Int? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
                as? [CFString: Any],
              let orientation = properties[kCGImagePropertyOrientation] as? NSNumber else {
            return nil
        }
        return orientation.intValue
    }

    private static func makeImage(width: Int, height: Int) throws -> CGImage {
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else {
            throw FixtureError.contextUnavailable
        }

        context.setFillColor(CGColor(red: 0.41, green: 0.25, blue: 0.16, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.setFillColor(CGColor(red: 0.95, green: 0.96, blue: 0.92, alpha: 1))
        context.fill(CGRect(x: width / 4, y: height / 4, width: width / 2, height: height / 2))
        context.setFillColor(CGColor(red: 0.93, green: 0.63, blue: 0.32, alpha: 1))
        context.fill(CGRect(x: width / 2, y: height / 2, width: width / 4, height: height / 3))

        guard let image = context.makeImage() else {
            throw FixtureError.contextUnavailable
        }
        return image
    }
}

private enum FixtureError: Error {
    case contextUnavailable
    case destinationUnavailable(String)
    case encodingFailed(String)
}
